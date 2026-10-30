#!/usr/bin/env bash
# Offline checks, run by CI and locally: scripts/lint.sh
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

fail=0
err() { echo "FAIL: $*" >&2; fail=1; }

mapfile -t sh_files < <(find src test scripts -name '*.sh' | sort)

echo "bash -n"
for f in "${sh_files[@]}"; do bash -n "$f" || err "syntax: $f"; done

echo "shellcheck"
command -v shellcheck >/dev/null || err "shellcheck not installed"
# test.sh files source dev-container-features-test-lib, which does not exist locally.
shellcheck -s bash -e SC1091 "${sh_files[@]}" || err "shellcheck"

echo "json"
while IFS= read -r f; do jq -e . "$f" >/dev/null || err "invalid json: $f"; done \
    < <(find src test .devcontainer -name '*.json' 2>/dev/null | sort)

echo "features"
for dir in src/*/; do
    id="$(basename "$dir")"
    [ "$(jq -r .id "$dir/devcontainer-feature.json")" = "$id" ] || err "$id: id does not match directory"
    jq -e '.options.version.default == "latest" or .options.version.default == "stable"' "$dir/devcontainer-feature.json" >/dev/null \
        || err "$id: missing version option"
    [ -x "$dir/install.sh" ] || err "$id: install.sh missing or not executable"
    [ -x "test/$id/test.sh" ] || err "$id: test/$id/test.sh missing or not executable"
    [ -f "test/$id/scenarios.json" ] || err "$id: test/$id/scenarios.json missing"
done

echo "common block"
common() { sed -n '/^# --- common/,/^# --- end common/p' "$1" | sha256sum; }
ref="$(common src/yq/install.sh)"
for f in src/*/install.sh; do [ "$(common "$f")" = "$ref" ] || err "$f: common block differs from src/yq/install.sh"; done

echo "no curl|sh"
! grep -nE '(curl|wget)[^|]*\|[[:space:]]*(sudo +)?(ba|z)?sh' src/*/install.sh || err "pipe to shell"

echo "workflows"
if grep -hE '^\s*-?\s*uses:' .github/workflows/*.y*ml | grep -vE 'uses: (actions|devcontainers)/[a-z-]+@[0-9a-f]{40}( |$)'; then
    err "workflow action not from actions/* or devcontainers/*, or not pinned to a full SHA"
fi

if [ "$fail" -ne 0 ]; then echo "FAILED" >&2; exit 1; fi
echo "OK"
