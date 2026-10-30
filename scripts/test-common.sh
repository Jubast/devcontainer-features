#!/usr/bin/env bash
# Offline tests of the fail-closed logic in the common install block (no root, no network).
# shellcheck disable=SC2016  # test commands are eval-ed on purpose, so single quotes are intended
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

fail=0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# The block as a sourceable file, without the root and apt checks, next to a fake checksums.txt.
sed -n '/^# --- common/,/^# --- end common/p' src/yq/install.sh | grep -vE 'Must run as root|Only Debian' > "$tmp/common.sh"
good=0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
cat > "$tmp/checksums.txt" <<LIST
# comment
0.9.9 tool-linux-x86_64 $good
0.9.10 tool-linux-x86_64 $good
LIST

# t NAME EXPECTED_RC CMD: run CMD with the block loaded, in a subshell.
t() {
    local name="$1" want="$2" rc
    ( cd "$tmp" && source ./common.sh 2>/dev/null && eval "$3" ) >/dev/null 2>&1
    rc=$?
    if { [ "$want" = 0 ] && [ "$rc" -eq 0 ]; } || { [ "$want" = fail ] && [ "$rc" -ne 0 ]; }; then
        echo "ok   $name"
    else
        echo "FAIL $name (rc=$rc)" >&2; fail=1
    fi
}

t "listed version resolves"       0    '[ "$(shipped_sha256 0.9.9 tool-linux-x86_64)" = "'$good'" ]'
t "unlisted version aborts"       fail 'shipped_sha256 0.9.8 tool-linux-x86_64'
t "unlisted asset aborts"         fail 'shipped_sha256 0.9.9 tool-linux-aarch64'
t "newest listed uses version order" 0 '[ "$(listed_versions | tail -n 1)" = 0.9.10 ]'
t "sha256 match passes"           0    'echo x > f; verify_sha256 f "$(sha256sum f | cut -d" " -f1)"'
t "sha256 mismatch aborts"        fail 'echo x > f; verify_sha256 f '$good
t "empty sha256 aborts"           fail 'echo x > f; verify_sha256 f ""'
t "uppercase sha256 aborts"       fail 'echo x > f; verify_sha256 f "$(sha256sum f | cut -d" " -f1 | tr a-f A-F)"'
t "plain version normalizes"      0    '[ "$(normalize_tag 1.2.3)" = v1.2.3 ]'
t "v-prefixed version normalizes" 0    '[ "$(normalize_tag v1.2)" = v1.2 ]'
for bad in '1.2.3;rm' '../x' '1.2.3-rc1' '' 'latest' '$(id)'; do
    t "version '$bad' is rejected" fail "normalize_tag '$bad'"
done

[ "$fail" -eq 0 ] || exit 1
