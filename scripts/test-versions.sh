#!/usr/bin/env bash
# Offline tests of scripts/check-versions.sh in a throwaway clone with a release tag.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

fail=0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

repo="$tmp/repo"
# Committed history, with the working tree (possibly uncommitted changes) laid over it.
git clone -q --no-hardlinks . "$repo"
find . -path ./.git -prune -o -type f -print0 | tar --null -T - -cf - | tar -xf - -C "$repo"
g() { git -C "$repo" -c user.name=test -c user.email=test@example.com "$@"; }
g tag -l | xargs -r git -C "$repo" tag -d >/dev/null
g add -A
g commit -q --allow-empty -m base
g tag v1.0.0
base="$(g rev-parse HEAD)"

set_version() { jq --arg v "$2" '.version = $v' "$repo/src/$1/devcontainer-feature.json" > "$tmp/j" && mv "$tmp/j" "$repo/src/$1/devcontainer-feature.json"; }

# t NAME EXPECT(pass|fail) [MATCH]: run the check in the clone, then reset it.
t() {
    local out rc
    out="$(cd "$repo" && bash scripts/check-versions.sh 2>&1)"; rc=$?
    if { [ "$2" = pass ] && [ "$rc" -eq 0 ]; } || { [ "$2" = fail ] && [ "$rc" -ne 0 ]; }; then
        if [ -n "${3:-}" ] && ! grep -q -- "$3" <<<"$out"; then
            echo "FAIL $1 (output lacks '$3': $out)" >&2; fail=1
        else
            echo "ok   $1"
        fi
    else
        echo "FAIL $1 (rc=$rc: $out)" >&2; fail=1
    fi
    g reset -q --hard "$base"; g clean -qfd
}

t "nothing changed" pass
echo "# edit" >> "$repo/src/yq/install.sh"
t "changed file without a bump fails" fail "yq: changed since v1.0.0 but version is still"
echo "# edit" >> "$repo/src/yq/install.sh"; set_version yq 99.0.0
t "changed file with a bump passes" pass
echo "# edit" >> "$repo/src/yq/install.sh"; set_version yq 0.0.1
t "downgrade fails" fail "version went down"
echo "# edit" >> "$repo/src/yq/README.md"
t "readme-only change passes" pass
echo "# edit" >> "$repo/src/yq/README.md"
echo "# edit" >> "$repo/src/yq/install.sh"
t "readme plus code change without a bump fails" fail
set_version yq 1.0.9; g commit -qam "tag base" ; g tag -f v1.0.0 >/dev/null; base="$(g rev-parse HEAD)"
echo "# edit" >> "$repo/src/yq/install.sh"; set_version yq 1.0.10
t "1.0.9 to 1.0.10 is an upgrade (version order, not text order)" pass
echo "# edit" >> "$repo/src/yq/install.sh"; set_version yq 1.0.8
t "1.0.9 to 1.0.8 is a downgrade" fail "version went down"

g tag -d v1.0.0 >/dev/null
t "no tags is skipped visibly" pass "no release tag"

git clone -q --depth 1 --no-tags "file://$repo" "$tmp/shallow"
out="$(cd "$tmp/shallow" && bash scripts/check-versions.sh 2>&1)"
if grep -q "WARNING: shallow clone" <<<"$out"; then echo "ok   shallow clone without tags warns"; else echo "FAIL shallow clone without tags is silent: $out" >&2; fail=1; fi

[ "$fail" -eq 0 ] || exit 1
