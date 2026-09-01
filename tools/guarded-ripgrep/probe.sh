#!/usr/bin/env bash
set -euo pipefail

guard_script=$(realpath "${1:?usage: probe.sh PATH_TO_RG_GUARD}")
probe_root=$(mktemp -d)
state_root=$probe_root/state
mkdir -p "$probe_root/narrow" "$state_root"
trap 'rm -rf -- "$probe_root"' EXIT

failures=0

run_guard() {
	(
		cd "$probe_root"
		RG_GUARD_REAL_RG=/bin/echo \
			RG_GUARD_TIMEOUT=/bin/echo \
			RG_GUARD_JQ=$(command -v jq) \
			RG_GUARD_GIT=$(command -v git) \
			RG_GUARD_PS=/bin/ps \
			XDG_STATE_HOME=$state_root \
			CODEX_THREAD_ID=probe-thread \
			CODEX_TURN_ID=probe-turn \
			CODEX_SESSION_ID=probe-session \
			bash "$guard_script" "$@"
	)
}

expect_denied() {
	local label=$1
	shift
	set +e
	run_guard "$@" >/dev/null 2>&1
	local status=$?
	set -e
	if (( status != 64 )); then
		printf 'not ok - %s (expected 64, got %d)\n' "$label" "$status"
		failures=$((failures + 1))
	else
		printf 'ok - %s\n' "$label"
	fi
}

expect_allowed() {
	local label=$1
	shift
	set +e
	run_guard "$@" >/dev/null 2>&1
	local status=$?
	set -e
	if (( status != 0 )); then
		printf 'not ok - %s (expected 0, got %d)\n' "$label" "$status"
		failures=$((failures + 1))
	else
		printf 'ok - %s\n' "$label"
	fi
}

expect_denied "double unrestricted short option" -uu needle .
expect_denied "repeated unrestricted short option" -u -u needle .
expect_denied "clustered unrestricted short option" -Huu needle .
expect_denied "triple unrestricted short option" -uuu needle .
expect_denied "hidden plus single unrestricted option" --hidden -u needle .
expect_denied "hidden short option plus no-ignore-dot" -. --no-ignore-dot needle .
expect_denied "hidden plus no-ignore-vcs" --hidden --no-ignore-vcs needle .
expect_allowed "single unrestricted option" -u needle .
expect_allowed "value-bearing short option is not unrestricted" -gu needle .
expect_allowed "pattern then narrow root after separator" -- needle narrow
expect_allowed "explicit pattern option then narrow root" -e needle -- narrow

set +e
(
	cd "$probe_root"
	RG_GUARD_SCOPE=/ \
		RG_GUARD_BROAD_REASON=caller-chosen \
		RG_GUARD_REAL_RG=/bin/echo \
		RG_GUARD_TIMEOUT=/bin/echo \
		RG_GUARD_JQ=$(command -v jq) \
		RG_GUARD_GIT=$(command -v git) \
		RG_GUARD_PS=/bin/ps \
		XDG_STATE_HOME=$state_root \
		bash "$guard_script" --hidden --no-ignore needle .
) >/dev/null 2>&1
override_status=$?
set -e
if (( override_status != 64 )); then
	printf 'not ok - caller environment cannot authorize broad traversal (expected 64, got %d)\n' "$override_status"
	failures=$((failures + 1))
else
	printf 'ok - caller environment cannot authorize broad traversal\n'
fi

git_directory=$probe_root/foreign.git
git init --bare --quiet "$git_directory"
set +e
(
	cd "$probe_root"
	GIT_DIR=$git_directory \
		GIT_WORK_TREE=/ \
		RG_GUARD_REAL_RG=/bin/echo \
		RG_GUARD_TIMEOUT=/bin/echo \
		RG_GUARD_JQ=$(command -v jq) \
		RG_GUARD_GIT=$(command -v git) \
		RG_GUARD_PS=/bin/ps \
		XDG_STATE_HOME=$state_root \
		bash "$guard_script" --hidden --no-ignore needle .
) >/dev/null 2>&1
git_environment_status=$?
set -e
if (( git_environment_status != 64 )); then
	printf 'not ok - Git environment cannot replace repository discovery (expected 64, got %d)\n' "$git_environment_status"
	failures=$((failures + 1))
else
	printf 'ok - Git environment cannot replace repository discovery\n'
fi

set +e
(
	cd /
	RG_GUARD_REAL_RG=/bin/echo \
		RG_GUARD_TIMEOUT=/bin/echo \
		RG_GUARD_JQ=$(command -v jq) \
		RG_GUARD_GIT=$(command -v git) \
		RG_GUARD_PS=/bin/ps \
		XDG_STATE_HOME=$state_root \
		bash "$guard_script" needle /
) >/dev/null 2>&1
filesystem_root_status=$?
set -e
if (( filesystem_root_status != 64 )); then
	printf 'not ok - filesystem root cannot become policy scope (expected 64, got %d)\n' "$filesystem_root_status"
	failures=$((failures + 1))
else
	printf 'ok - filesystem root cannot become policy scope\n'
fi

rm -f -- "$state_root/rg-guard/invocations.jsonl"
run_guard --replace sensitive-option-value sensitive-pattern narrow >/dev/null
log_file=$state_root/rg-guard/invocations.jsonl
if [[ $(<"$log_file") == *sensitive-option-value* || $(<"$log_file") == *sensitive-pattern* ]]; then
	printf 'not ok - log redacts pattern and option values\n'
	failures=$((failures + 1))
elif ! jq -e \
	--arg root "$(realpath "$probe_root/narrow")" \
	'.roots == [$root]
	 and .root_count == 1
	 and .pattern_source == "positional"
	 and (.flag_classes | index("option-with-value"))
	 and .thread_id == "probe-thread"
	 and .turn_id == "probe-turn"
	 and .session_id == "probe-session"' "$log_file" >/dev/null; then
	printf 'not ok - log retains attribution and root/flag-class evidence\n'
	failures=$((failures + 1))
else
	printf 'ok - log redacts content and retains structural evidence\n'
fi

if (( failures > 0 )); then
	exit 1
fi
