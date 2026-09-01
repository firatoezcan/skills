#!/usr/bin/env bash
set -euo pipefail

usage='usage: codex-path-probe.sh PATH_TO_GUARD_SCRIPT PATH_TO_REQUIRE_WRAPPER_CONFIG PATH_TO_RAW_RG PATH_TO_TIMEOUT PATH_TO_JQ PATH_TO_GIT PATH_TO_PS'
guard_script=$(realpath "${1:?$usage}")
require_wrapper_config=$(realpath "${2:?$usage}")
raw_rg=$(realpath "${3:?$usage}")
timeout_command=$(realpath "${4:?$usage}")
jq_command=$(realpath "${5:?$usage}")
git_command=$(realpath "${6:?$usage}")
ps_command=$(realpath "${7:?$usage}")
probe_root=$(mktemp -d)
codex_path=$probe_root/codex-path
guard_path=$probe_root/guard-path
search_root=$probe_root/search-root
state_root=$probe_root/state
mkdir -p "$codex_path" "$guard_path" "$search_root/narrow" "$state_root"
trap 'rm -rf -- "$probe_root"' EXIT

ln -s "$raw_rg" "$codex_path/rg"
{
	printf '#!/usr/bin/env bash\n'
	printf 'export RG_GUARD_REAL_RG=%q\n' "$raw_rg"
	printf 'export RG_GUARD_TIMEOUT=%q\n' "$timeout_command"
	printf 'export RG_GUARD_JQ=%q\n' "$jq_command"
	printf 'export RG_GUARD_GIT=%q\n' "$git_command"
	printf 'export RG_GUARD_PS=%q\n' "$ps_command"
	printf 'exec bash %q "$@"\n' "$guard_script"
} >"$guard_path/rg"
chmod +x "$guard_path/rg"
printf '%s\n' needle >"$search_root/narrow/input.txt"

codex_shaped_path=$codex_path:$guard_path:$PATH
resolved=$(PATH=$codex_shaped_path command -v rg)
if [[ $resolved != "$codex_path/rg" ]]; then
	printf 'not ok - Codex-shaped PATH resolves the bundled ripgrep first\n'
	exit 1
fi

env -u RIPGREP_CONFIG_PATH PATH="$codex_shaped_path" rg --files -- "$search_root" >/dev/null
printf 'ok - Codex-shaped PATH bypasses the guard without a fail-closed config\n'

set +e
RIPGREP_CONFIG_PATH=$require_wrapper_config PATH=$codex_shaped_path \
	rg --files -- "$search_root" >"$probe_root/raw.out" 2>"$probe_root/raw.err"
raw_status=$?
set -e
if (( raw_status == 0 )) || [[ $(<"$probe_root/raw.err") != *guarded-ripgrep-wrapper-required* ]]; then
	printf 'not ok - fail-closed config blocks bundled ripgrep\n'
	exit 1
fi
printf 'ok - fail-closed config blocks bundled ripgrep\n'

guarded_path=$guard_path:$codex_path:$PATH
resolved=$(PATH=$guarded_path command -v rg)
if [[ $resolved != "$guard_path/rg" ]]; then
	printf 'not ok - restored shell lookup resolves the guard first\n'
	exit 1
fi

(
	cd "$search_root"
	RIPGREP_CONFIG_PATH=$require_wrapper_config \
		XDG_STATE_HOME=$state_root \
		PATH=$guarded_path \
		rg needle -- narrow >/dev/null
)
printf 'ok - restored shell lookup runs the guard with the fail-closed config active\n'
