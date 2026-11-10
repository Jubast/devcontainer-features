#!/bin/bash
set -e

source dev-container-features-test-lib

installed=/usr/local/share/devcontainer-features/codex
configure="$installed/configure.sh"

# Runs in a temporary HOME and state directory (a copy of the installed options), never the real ones.
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir "$tmp/state" "$tmp/home" "$tmp/stub" "$tmp/yq-only" "$tmp/failing"
cp "$installed/options.env" "$tmp/state/"
export HOME="$tmp/home" HARNESS_STATE_DIR="$tmp/state"
unset CODEX_HOME

# A stub CLI records its arguments, so the test needs no network.
stub="$tmp/stub"
printf '#!/bin/sh\necho "$*" >> "%s/calls"\n' "$stub" > "$stub/codex"
chmod +x "$stub/codex"

# Without the CLI on the PATH (yq stays), apply only merges the settings and warns.
yq_only="$tmp/yq-only"
ln -s "$(command -v yq)" "$yq_only/yq"
PATH="$yq_only:/usr/bin:/bin" "$configure" apply >"$stub/absent.log" 2>&1
check "absent CLI warns" grep -F 'is not installed' "$stub/absent.log"

settings="$HOME/.codex/config.toml"
# Unrelated and sibling keys survive a re-apply.
yq -i -p toml -o toml '.unrelated = 1 | .history.other = 1' "$settings"
PATH="$stub:$PATH" "$configure" apply

check "settings merged" yq -p toml -e '.model == "o3" and .history.persistence == "none"' "$settings"
check "sibling key kept" yq -p toml -e '.history.other == 1' "$settings"
check "unrelated key kept" yq -p toml -e '.unrelated == 1' "$settings"
check "marketplace added" grep -Fx 'plugin marketplace add Jubast/common-agent-marketplace@v0.2.1' "$stub/calls"
check "plugin installed" grep -Fx 'plugin add conventional-changes@common-agent-marketplace' "$stub/calls"

failing="$tmp/failing"
printf '#!/bin/sh\nexit 1\n' > "$failing/codex"
chmod +x "$failing/codex"
apply_with_failing_cli() { PATH="$failing:$PATH" "$configure" apply >"$failing/log" 2>&1; }
check "failing CLI does not fail apply" apply_with_failing_cli
check "failing CLI warns" grep -F WARNING "$failing/log"

reportResults
