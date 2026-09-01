set -euo pipefail

readonly maximum_roots=16
readonly maximum_threads=4
readonly timeout_seconds=60
readonly real_rg=${RG_GUARD_REAL_RG:?}
readonly timeout_command=${RG_GUARD_TIMEOUT:?}
readonly jq_command=${RG_GUARD_JQ:?}
readonly git_command=${RG_GUARD_GIT:?}
readonly ps_command=${RG_GUARD_PS:?}

original_args=("$@")
search_roots=()
effective_args=(--threads "$maximum_threads" "${original_args[@]}")
hidden=false
ignores_disabled=false
separator_index=-1
thread_value=

usage() {
	printf '%s\n' \
		"rg guard: give rg an explicit root, preferably after --" \
		"rg guard: example: rg -n 'pattern' -- src/server" \
		"rg guard: repo-wide --hidden plus --no-ignore searches are refused" \
		"rg guard: an authorized broad search must set an exact RG_GUARD_SCOPE and RG_GUARD_BROAD_REASON"
}

case ${1-} in
	--guard-help)
		usage
		exit 0
		;;
	-h|--help|-V|--version|--type-list|--pcre2-version)
		if (( $# == 1 )); then
			exec "$real_rg" "$@"
		fi
		;;
esac

for ((index = 0; index < ${#original_args[@]}; index++)); do
	argument=${original_args[index]}
	if [[ $argument == -- ]]; then
		separator_index=$index
		break
	fi

	case $argument in
		--hidden)
			hidden=true
			;;
		--no-ignore|-uuu)
			ignores_disabled=true
			[[ $argument == -uuu ]] && hidden=true
			;;
		--threads)
			if (( index + 1 >= ${#original_args[@]} )); then
				printf '%s\n' "rg guard: --threads requires a value" >&2
				exit 64
			fi
			thread_value=${original_args[index + 1]}
			((index++))
			;;
		--threads=*)
			thread_value=${argument#*=}
			;;
		-j)
			if (( index + 1 >= ${#original_args[@]} )); then
				printf '%s\n' "rg guard: -j requires a value" >&2
				exit 64
			fi
			thread_value=${original_args[index + 1]}
			((index++))
			;;
		-j*)
			thread_value=${argument#-j}
			thread_value=${thread_value#=}
			;;
	esac
done

if [[ -n $thread_value ]]; then
	if [[ ! $thread_value =~ ^[1-9][0-9]*$ ]] || (( thread_value > maximum_threads )); then
		printf '%s\n' "rg guard: thread count must be between 1 and $maximum_threads" >&2
		exit 64
	fi
fi

if (( separator_index >= 0 )); then
	for ((index = separator_index + 1; index < ${#original_args[@]}; index++)); do
		search_roots+=("${original_args[index]}")
	done
else
	for ((index = ${#original_args[@]} - 1; index >= 0; index--)); do
		argument=${original_args[index]}
		if [[ $argument == -* || ! -e $argument ]]; then
			break
		fi
		if (( ${#search_roots[@]} == 0 )); then
			search_roots=("$argument")
		else
			search_roots=("$argument" "${search_roots[@]}")
		fi
	done
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
repo_root=$($git_command -C "$cwd" rev-parse --show-toplevel 2>/dev/null || true)
if [[ -n $repo_root ]]; then
	repo_root=$(realpath -e -- "$repo_root")
fi

scope_override=false
scope_reason=
if [[ -n ${RG_GUARD_SCOPE:-} ]]; then
	if [[ -z ${RG_GUARD_BROAD_REASON:-} ]]; then
		printf '%s\n' "rg guard: RG_GUARD_SCOPE requires RG_GUARD_BROAD_REASON" >&2
		exit 64
	fi
	if [[ ${RG_GUARD_SCOPE} != /* || ! -d ${RG_GUARD_SCOPE} ]]; then
		printf '%s\n' "rg guard: RG_GUARD_SCOPE must be an existing absolute directory" >&2
		exit 66
	fi
	policy_scope=$(realpath -e -- "$RG_GUARD_SCOPE")
	scope_override=true
	scope_reason=$RG_GUARD_BROAD_REASON
elif [[ -n $repo_root ]]; then
	policy_scope=$repo_root
else
	policy_scope=$cwd
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
	[[ $resolved_root == "$policy_scope" ]] && searches_scope_root=true
done

decision="allow"
reason="scoped-search"
if [[ $hidden == true && $ignores_disabled == true && $searches_scope_root == true ]]; then
	if [[ $scope_override == true ]]; then
		reason="authorized-broad-search"
	else
		decision="deny"
		reason="hidden-no-ignore-at-scope-root"
	fi
elif [[ $scope_override == true ]]; then
	reason="authorized-scope-override"
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
	--arg scope_reason "$scope_reason" \
	--arg decision "$decision" \
	--arg reason "$reason" \
	--args "\$ARGS.named + {argv: \$ARGS.positional}" \
	-- "${original_args[@]}" >>"$log_file"

if [[ $decision == deny ]]; then
	printf '%s\n' \
		"rg guard: refusing --hidden with --no-ignore or -uuu at the repository or working root" \
		"rg guard: search a narrower directory, or use an authorized RG_GUARD_SCOPE with RG_GUARD_BROAD_REASON" >&2
	exit 64
fi

exec "$timeout_command" --foreground --signal=TERM --kill-after=5s "${timeout_seconds}s" \
	"$real_rg" "${effective_args[@]}"
