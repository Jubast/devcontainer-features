#!/bin/bash
set -e

source dev-container-features-test-lib

installed=/usr/local/share/devcontainer-features/claude
configure="$installed/configure.sh"

# Runs in a temporary HOME and state directory (a copy of the installed options), never the real ones.
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir "$tmp/state" "$tmp/home" "$tmp/stub" "$tmp/failing"
cp "$installed/options.env" "$tmp/state/"
export HOME="$tmp/home" HARNESS_STATE_DIR="$tmp/state"

# A stub CLI records its arguments, so the test needs no network.
stub="$tmp/stub"
printf '#!/bin/sh\necho "$*" >> "%s/calls"\n' "$stub" > "$stub/claude"
chmod +x "$stub/claude"

# Without the CLI on the PATH, apply only warns.
PATH="/usr/bin:/bin" "$configure" apply >"$stub/absent.log" 2>&1
check "absent CLI warns" grep -F 'is not installed' "$stub/absent.log"

PATH="$stub:$PATH" "$configure" apply

check "marketplace added" grep -Fx 'plugin marketplace add Jubast/common-agent-marketplace#v0.2.1 --scope user' "$stub/calls"
check "plugin installed" grep -Fx 'plugin install chief@common-agent-marketplace --scope user' "$stub/calls"

failing="$tmp/failing"
printf '#!/bin/sh\nexit 1\n' > "$failing/claude"
chmod +x "$failing/claude"
apply_with_failing_cli() { PATH="$failing:$PATH" "$configure" apply >"$failing/log" 2>&1; }
check "failing CLI does not fail apply" apply_with_failing_cli
check "failing CLI warns" grep -F WARNING "$failing/log"

reportResults
