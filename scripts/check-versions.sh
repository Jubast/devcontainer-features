#!/usr/bin/env bash
# A feature whose files changed since the latest release tag needs a higher version in its
# devcontainer-feature.json, or the publisher skips it. README-only edits need no release.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

fail=0
tag="$(git describe --tags --abbrev=0 --match 'v*' 2>/dev/null || true)"
if [ -z "$tag" ]; then
    if [ "$(git rev-parse --is-shallow-repository)" = true ]; then
        echo "WARNING: shallow clone without tags, version check NOT run (git fetch --unshallow --tags)" >&2
    else
        echo "no release tag, version check skipped"
    fi
    exit 0
fi

for dir in src/*/; do
    id="$(basename "$dir")"
    git cat-file -e "$tag:src/$id/devcontainer-feature.json" 2>/dev/null || continue
    # Changed files other than the README.
    changed="$(git diff --name-only "$tag" -- "src/$id" | grep -v "^src/$id/README\.md$" || true)"
    [ -n "$changed" ] || continue
    old="$(git show "$tag:src/$id/devcontainer-feature.json" | jq -r .version)"
    new="$(jq -r .version "src/$id/devcontainer-feature.json")"
    if [ "$new" = "$old" ]; then
        echo "FAIL: $id: changed since $tag but version is still $old" >&2; fail=1
    elif [ "$(printf '%s\n%s\n' "$old" "$new" | sort -V | head -n 1)" != "$old" ]; then
        echo "FAIL: $id: version went down from $old (in $tag) to $new" >&2; fail=1
    fi
done
exit "$fail"
