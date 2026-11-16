#!/bin/bash
set -e

source dev-container-features-test-lib

configure=/usr/local/share/devcontainer-features/copilot/configure.sh
root() { if [ "$(id -u)" -eq 0 ]; then "$@"; else sudo "$@"; fi; }

# Runs in a temporary HOME and state directory, never the real ones.
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir "$tmp/state" "$tmp/home"
export HOME="$tmp/home" HARNESS_STATE_DIR="$tmp/state"
# install_with VAR=VALUE...: run `configure.sh install` as root with these options.
install_with() { root env HARNESS_STATE_DIR="$tmp/state" _REMOTE_USER="$(id -un)" _REMOTE_USER_HOME="$HOME" "$@" "$configure" install; }
# rejects MESSAGE VAR=VALUE...: install fails and says MESSAGE.
rejects() {
    local message="$1" output
    shift
    if output="$(install_with "$@" 2>&1)"; then return 1; fi
    grep -qF "$message" <<<"$output"
}

check "copilot on PATH" command -v copilot
check "copilot runs" copilot --version
check "configure.sh installed" test -x "$configure"
check "install with no options succeeds" install_with
check "apply with no options succeeds" "$tmp/state/configure.sh" apply
check "entry starting with a dash is rejected" rejects 'Invalid entry' PLUGINS='--evil'

reportResults
