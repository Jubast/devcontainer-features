#!/bin/bash
set -e

source dev-container-features-test-lib

configure=/usr/local/share/devcontainer-features/codex/configure.sh
root() { if [ "$(id -u)" -eq 0 ]; then "$@"; else sudo "$@"; fi; }

# Runs in a temporary HOME and state directory, never the real ones.
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir "$tmp/state" "$tmp/home"
export HOME="$tmp/home" HARNESS_STATE_DIR="$tmp/state"
unset CODEX_HOME
# install_with VAR=VALUE...: run `configure.sh install` as root with these options.
install_with() { root env HARNESS_STATE_DIR="$tmp/state" _REMOTE_USER="$(id -un)" _REMOTE_USER_HOME="$HOME" "$@" "$configure" install; }
# rejects MESSAGE VAR=VALUE...: install fails and says MESSAGE.
rejects() {
    local message="$1" output
    shift
    if output="$(install_with "$@" 2>&1)"; then return 1; fi
    grep -qF "$message" <<<"$output"
}

check "codex on PATH" command -v codex
check "codex runs" codex --version
check "configure.sh installed" test -x "$configure"
check "install with no options succeeds" install_with
check "apply with no options succeeds" "$tmp/state/configure.sh" apply
check "settings that is not an object is rejected" rejects 'must be a JSON object' SETTINGS='[1]'
check "entry starting with a dash is rejected" rejects 'Invalid entry' PLUGINS='--evil'

# The container CLI sources option values from KEY="value" lines, which drops double quotes.
printf 'SETTINGS="%s"\n' "{'model':'sonnet','env':{'EDITOR':'vim'},'name':'it\u0027s'}" > "$tmp/options"
cat > "$tmp/install" <<'EOF'
set -a; . "$1"; set +a
exec "$2" install
EOF
install_from_env_file() { root env HARNESS_STATE_DIR="$tmp/state" _REMOTE_USER="$(id -un)" _REMOTE_USER_HOME="$HOME" bash "$tmp/install" "$tmp/options" "$configure"; }
check "settings with single quotes install" install_from_env_file
stored_settings() { (. "$tmp/state/options.env" && echo "$SETTINGS"); }
check "settings stored as JSON" test "$(stored_settings)" = '{"model":"sonnet","env":{"EDITOR":"vim"},"name":"it\u0027s"}'
check "stored settings apply" "$tmp/state/configure.sh" apply
check "stored settings merged" yq -p toml -e '.model == "sonnet" and .env.EDITOR == "vim" and (.name | length) == 4' "$HOME/.codex/config.toml"
check "settings that lost their quotes are rejected" rejects 'must be a JSON object' SETTINGS='{model:sonnet}'

reportResults
