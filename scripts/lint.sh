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
    < <(find src test -name '*.json' | sort)

echo "features"
for dir in src/*/; do
    id="$(basename "$dir")"
    [ "$(jq -r .id "$dir/devcontainer-feature.json")" = "$id" ] || err "$id: id does not match directory"
    jq -e '.options.version.default == "latest" or .options.version.default == "stable"' "$dir/devcontainer-feature.json" >/dev/null \
        || err "$id: missing version option"
    [ -f "$dir/install.sh" ] || err "$id: install.sh missing"
    [ -f "test/$id/test.sh" ] || err "$id: test/$id/test.sh missing"
    [ -f "test/$id/scenarios.json" ] || err "$id: test/$id/scenarios.json missing"
done

echo "version bumps"
# A feature whose files changed since the latest release tag needs a new version, or it is never published.
tag="$(git describe --tags --abbrev=0 --match 'v*' 2>/dev/null || true)"
if [ -z "$tag" ]; then
    echo "no release tag, skipped"
else
    for dir in src/*/; do
        id="$(basename "$dir")"
        git cat-file -e "$tag:src/$id/devcontainer-feature.json" 2>/dev/null || continue
        git diff --quiet "$tag" -- "src/$id" && continue
        [ "$(git show "$tag:src/$id/devcontainer-feature.json" | jq -r .version)" != "$(jq -r .version "src/$id/devcontainer-feature.json")" ] \
            || err "$id: changed since $tag but version is unchanged"
    done
fi

echo "checksums"
for f in src/*/checksums.txt; do
    id="$(basename "$(dirname "$f")")"
    bad="$(grep -vE '^(#.*|[0-9]+(\.[0-9]+){1,2} [^ ]+ [0-9a-f]{64})$' "$f" | grep -v '^$' || true)"
    [ -z "$bad" ] || err "$f: malformed line(s): $bad"
    [ -z "$(awk '$1 !~ /^#/ && NF { print $1, $2 }' "$f" | sort | uniq -d)" ] || err "$f: duplicate version/asset"
    [ -n "$(awk '$1 !~ /^#/ && NF' "$f")" ] || err "$f: no entries"
    # every listed version needs an amd64 and an arm64 asset
    while read -r v; do
        [ "$(awk -v v="$v" '$1 == v' "$f" | wc -l)" -ge 2 ] || err "$f: $v lacks an asset per architecture"
    done < <(awk '$1 !~ /^#/ && NF { print $1 }' "$f" | sort -u)
    grep -q checksums.txt "src/$id/README.md" || err "$id: README does not mention checksums.txt"
done
for id in herdr gcm shellcheck; do [ -f "src/$id/checksums.txt" ] || err "$id: checksums.txt missing"; done

echo "declared dependencies"
# Bare images (debian:12) have none of these; each installer must ensure what it uses.
for f in src/*/install.sh; do
    body="$(sed '/^# --- common/,/^# --- end common/d' "$f")"
    pkgs="$(grep -h '^ *ensure_pkgs ' <<<"$body" | tr '\n' ' ')"
    need() { # PATTERN PACKAGE
        if grep -qE "$1" <<<"$body" && ! grep -qw -- "$2" <<<"$pkgs"; then err "$f: uses '$1' but ensure_pkgs lacks $2"; fi
    }
    need '\b(download|resolve_tag|latest_tag)\b' curl
    need '\b(download|resolve_tag|latest_tag)\b' ca-certificates
    need 'tar -x' tar
    need 'tar -xJf' xz-utils
    need 'git-credential-manager' git
    need '\bjq\b' jq
    need 'python3 -m' python3
    need 'python3 -m' ca-certificates
    need '\bunzip\b' unzip
done

echo "no api calls at install time"
! grep -n 'api\.github\.com' src/*/install.sh || err "install.sh must not call api.github.com"

echo "scenarios"
# Every scenario needs <name>.sh beside its scenarios.json, and only declared options.
while IFS= read -r f; do
    dir="$(dirname "$f")"
    while IFS= read -r name; do
        [ -f "$dir/$name.sh" ] || err "$f: scenario '$name' has no $dir/$name.sh"
    done < <(jq -r 'keys[]' "$f")
    while IFS=$'\t' read -r feature option; do
        [ -f "src/$feature/devcontainer-feature.json" ] || { err "$f: unknown feature '$feature'"; continue; }
        jq -e --arg o "$option" '.options[$o]' "src/$feature/devcontainer-feature.json" >/dev/null \
            || err "$f: feature '$feature' has no option '$option'"
    done < <(jq -r '.[].features | to_entries[] | .key as $k | (.value | keys[]) | [$k, .] | @tsv' "$f")
done < <(find test -name scenarios.json | sort)
for dir in src/*/; do
    grep -qw "$(basename "$dir")" .github/workflows/test.yaml || err "$(basename "$dir"): missing from the test.yaml matrix"
done

echo "executable bit"
# Check the mode recorded in git: the filesystem can lie (core.fileMode=false).
while read -r mode _ _ f; do
    [ "$mode" = 100755 ] || err "$f: git mode is $mode, expected 100755 (git update-index --chmod=+x)"
done < <(git ls-files -s -- '*.sh')

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
