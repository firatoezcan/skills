set -euo pipefail

readonly maximum_roots=16
readonly maximum_threads=4
readonly timeout_seconds=60
readonly real_rg=${RG_GUARD_REAL_RG:?}
readonly timeout_command=${RG_GUARD_TIMEOUT:?}
readonly jq_command=${RG_GUARD_JQ:?}
readonly git_command=${RG_GUARD_GIT:?}
readonly ps_command=${RG_GUARD_PS:?}
readonly -a real_rg_prefix=(--no-config)

original_args=("$@")
search_roots=()
resolved_roots=()
positionals=()
flag_classes=()
effective_args=("${real_rg_prefix[@]}" --threads "$maximum_threads" "${original_args[@]}")
hidden=false
ignores_disabled=false
files_mode=false
pattern_supplied=false
pattern_source=positional
unrestricted_count=0

usage() {
	printf '%s\n' \
		"rg guard: give rg an explicit root" \
		"rg guard: example: rg -n 'pattern' -- src/server" \
		"rg guard: repo-wide hidden plus ignore-disabled searches are refused" \
		"rg guard: broad traversals have no caller-controlled override"
}

record_flag_class() {
	local candidate=$1
	local existing
	for existing in "${flag_classes[@]}"; do
		[[ $existing == "$candidate" ]] && return
	done
	flag_classes+=("$candidate")
}

validate_thread_value() {
	local value=$1
	if [[ ! $value =~ ^[1-9][0-9]*$ ]] || (( 10#$value > maximum_threads )); then
		printf '%s\n' "rg guard: thread count must be between 1 and $maximum_threads" >&2
		exit 64
	fi
}

require_following_value() {
	local option=$1
	local index=$2
	if (( index + 1 >= ${#original_args[@]} )); then
		printf '%s\n' "rg guard: $option requires a value" >&2
		exit 64
	fi
}

case ${1-} in
	--guard-help)
		usage
		exit 0
		;;
	-h|--help|-V|--version|--type-list|--pcre2-version)
		if (( $# == 1 )); then
			exec "$real_rg" "${real_rg_prefix[@]}" "$@"
		fi
		;;
esac

index=0
while (( index < ${#original_args[@]} )); do
	argument=${original_args[index]}

	if [[ $argument == -- ]]; then
		record_flag_class separator
		index=$((index + 1))
		while (( index < ${#original_args[@]} )); do
			positionals+=("${original_args[index]}")
			index=$((index + 1))
		done
		break
	fi

	case $argument in
		--hidden)
			hidden=true
			record_flag_class hidden
			;;
		--no-ignore|--no-ignore-dot|--no-ignore-exclude|--no-ignore-files|--no-ignore-global|--no-ignore-parent|--no-ignore-vcs)
			ignores_disabled=true
			record_flag_class ignore-disabled
			;;
		--unrestricted)
			unrestricted_count=$((unrestricted_count + 1))
			record_flag_class unrestricted
			;;
		--files)
			files_mode=true
			pattern_source=none
			record_flag_class file-listing
			;;
		--regexp|--file)
			require_following_value "$argument" "$index"
			pattern_supplied=true
			pattern_source=option
			record_flag_class explicit-pattern
			index=$((index + 1))
			;;
		--regexp=*|--file=*)
			pattern_supplied=true
			pattern_source=option
			record_flag_class explicit-pattern
			;;
		--threads)
			require_following_value "$argument" "$index"
			validate_thread_value "${original_args[index + 1]}"
			record_flag_class explicit-thread-limit
			index=$((index + 1))
			;;
		--threads=*)
			validate_thread_value "${argument#*=}"
			record_flag_class explicit-thread-limit
			;;
		--after-context|--before-context|--color|--colors|--context|--context-separator|--dfa-size-limit|--encoding|--engine|--field-context-separator|--field-match-separator|--glob|--hostname-bin|--hyperlink-format|--iglob|--ignore-file|--max-columns|--max-count|--max-depth|--max-filesize|--path-separator|--pre|--pre-glob|--regex-size-limit|--replace|--sort|--sortr|--type|--type-add|--type-clear|--type-not)
			require_following_value "$argument" "$index"
			record_flag_class option-with-value
			index=$((index + 1))
			;;
		--*=*)
			record_flag_class option-with-value
			;;
		--*)
			record_flag_class other-option
			;;
		-?*)
			cluster=${argument#-}
			cluster_index=0
			while (( cluster_index < ${#cluster} )); do
				short_option=${cluster:cluster_index:1}
				case $short_option in
					.)
						hidden=true
						record_flag_class hidden
						;;
					u)
						unrestricted_count=$((unrestricted_count + 1))
						record_flag_class unrestricted
						;;
					e|f)
						pattern_supplied=true
						pattern_source=option
						record_flag_class explicit-pattern
						if (( cluster_index + 1 >= ${#cluster} )); then
							require_following_value "-$short_option" "$index"
							index=$((index + 1))
						fi
						break
						;;
					j)
						record_flag_class explicit-thread-limit
						if (( cluster_index + 1 < ${#cluster} )); then
							thread_value=${cluster:cluster_index + 1}
							thread_value=${thread_value#=}
						else
							require_following_value "-$short_option" "$index"
							index=$((index + 1))
							thread_value=${original_args[index]}
						fi
						validate_thread_value "$thread_value"
						break
						;;
					A|B|C|E|g|M|m|r|t|T)
						record_flag_class option-with-value
						if (( cluster_index + 1 >= ${#cluster} )); then
							require_following_value "-$short_option" "$index"
							index=$((index + 1))
						fi
						break
						;;
					*)
						record_flag_class other-option
						;;
				esac
				cluster_index=$((cluster_index + 1))
			done
			;;
		*)
			positionals+=("$argument")
			;;
	esac

	index=$((index + 1))
done

if (( unrestricted_count >= 1 )); then
	ignores_disabled=true
	record_flag_class ignore-disabled
fi
if (( unrestricted_count >= 2 )); then
	hidden=true
	record_flag_class hidden
fi

if [[ $files_mode == true || $pattern_supplied == true ]]; then
	search_roots=("${positionals[@]}")
elif (( ${#positionals[@]} > 0 )); then
	search_roots=("${positionals[@]:1}")
fi

if (( ${#search_roots[@]} == 0 )); then
	printf '%s\n' "rg guard: refusing an implicit search root" >&2
	usage >&2
	exit 64
fi

if (( ${#search_roots[@]} > maximum_roots )); then
	printf '%s\n' "rg guard: refusing ${#search_roots[@]} roots; narrow the search" >&2
	exit 64
fi

cwd=$(pwd -P)
repo_root=$(env -u GIT_DIR -u GIT_WORK_TREE "$git_command" -C "$cwd" rev-parse --show-toplevel 2>/dev/null || true)
if [[ -n $repo_root ]]; then
	repo_root=$(realpath -e -- "$repo_root")
	policy_scope=$repo_root
else
	policy_scope=$cwd
fi
if [[ $policy_scope == / ]]; then
	printf '%s\n' "rg guard: refusing the filesystem root as policy scope" >&2
	exit 64
fi

searches_scope_root=false
for search_root in "${search_roots[@]}"; do
	if [[ ! -e $search_root ]]; then
		printf '%s\n' "rg guard: search root does not resolve: $search_root" >&2
		exit 66
	fi
	resolved_root=$(realpath -e -- "$search_root")
	case $policy_scope in
		/)
			;;
		*)
			if [[ $resolved_root != "$policy_scope" && $resolved_root != "$policy_scope"/* ]]; then
				printf '%s\n' "rg guard: search root leaves the allowed scope: $search_root" >&2
				exit 64
			fi
			;;
	esac
	resolved_roots+=("$resolved_root")
	[[ $resolved_root == "$policy_scope" ]] && searches_scope_root=true
done

decision=allow
reason='scoped-search'
if [[ $hidden == true && $ignores_disabled == true && $searches_scope_root == true ]]; then
	decision=deny
	reason='hidden-no-ignore-at-scope-root'
fi

state_root=${XDG_STATE_HOME:-${HOME:?}/.local/state}
log_directory=$state_root/rg-guard
log_file=$log_directory/invocations.jsonl
if ! mkdir -p -- "$log_directory" || ! touch -- "$log_file" || ! chmod 700 "$log_directory" || ! chmod 600 "$log_file"; then
	printf '%s\n' "rg guard: cannot create the invocation log" >&2
	exit 73
fi

pgid=$($ps_command -o pgid= -p $$ 2>/dev/null || true)
pgid=${pgid//[[:space:]]/}
timestamp=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
roots_json=$($jq_command -cn --args "\$ARGS.positional" -- "${resolved_roots[@]}")
flag_classes_json=$($jq_command -cn --args "\$ARGS.positional" -- "${flag_classes[@]}")

$jq_command -cn \
	--arg timestamp "$timestamp" \
	--arg executable "$real_rg" \
	--arg timeout_executable "$timeout_command" \
	--arg cwd "$cwd" \
	--arg pid "$$" \
	--arg ppid "$PPID" \
	--arg pgid "$pgid" \
	--arg thread_id "${CODEX_THREAD_ID:-${CLAUDE_SESSION_ID:-${OPENCODE_SESSION_ID:-}}}" \
	--arg turn_id "${CODEX_TURN_ID:-}" \
	--arg session_id "${CODEX_SESSION_ID:-}" \
	--arg scope "$policy_scope" \
	--arg pattern_source "$pattern_source" \
	--arg decision "$decision" \
	--arg reason "$reason" \
	--argjson root_count "${#resolved_roots[@]}" \
	--argjson roots "$roots_json" \
	--argjson flag_classes "$flag_classes_json" \
	"\$ARGS.named + {root_count: \$root_count, roots: \$roots, flag_classes: \$flag_classes}" >>"$log_file"

if [[ $decision == deny ]]; then
	printf '%s\n' \
		"rg guard: refusing hidden plus ignore-disabled search at the repository or working root" \
		"rg guard: search a narrower directory; broad traversal cannot be authorized by caller environment" >&2
	exit 64
fi

exec "$timeout_command" --foreground --signal=TERM --kill-after=5s "${timeout_seconds}s" \
	"$real_rg" "${effective_args[@]}"
