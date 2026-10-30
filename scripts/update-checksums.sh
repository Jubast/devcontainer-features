#!/usr/bin/env bash
# Maintainer tool: add a release's assets to src/<feature>/checksums.txt.
# usage: scripts/update-checksums.sh <herdr|gcm|shellcheck> <version>...
# Hashes are computed from the downloaded assets and cross-checked against the digest
# GitHub records for them (GITHUB_TOKEN is used for the API if set). Review the diff.
set -euo pipefail
cd "$(dirname "$0")/.." || exit 1

[ "$#" -ge 2 ] || { sed -n '2,3p' "$0" | sed 's/^# //' >&2; exit 2; }
feature="$1"; shift

case "$feature" in
    herdr) repo=herdrdev/herdr ;;
    gcm) repo=git-ecosystem/git-credential-manager ;;
    shellcheck) repo=koalaman/shellcheck ;;
    *) echo "Unknown feature: $feature" >&2; exit 2 ;;
esac

assets() { # version
    case "$feature" in
        herdr) echo herdr-linux-x86_64 herdr-linux-aarch64 ;;
        gcm) echo "gcm-linux-x64-$1.deb" "gcm-linux-arm64-$1.deb" ;;
        shellcheck) echo "shellcheck-v$1.linux.x86_64.tar.xz" "shellcheck-v$1.linux.aarch64.tar.xz" ;;
    esac
}

file="src/$feature/checksums.txt"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

for version in "$@"; do
    version="${version#v}"
    [[ "$version" =~ ^[0-9]+(\.[0-9]+){1,2}$ ]] || { echo "Invalid version: $version" >&2; exit 2; }
    api="$(curl -fsSL ${GITHUB_TOKEN:+-H "Authorization: Bearer $GITHUB_TOKEN"} \
        "https://api.github.com/repos/$repo/releases/tags/v$version")" \
        || { echo "Release v$version not found in $repo (or API rate limited)." >&2; exit 1; }
    for asset in $(assets "$version"); do
        if grep -qE "^$version $asset " "$file" 2>/dev/null; then echo "skip (listed): $version $asset"; continue; fi
        curl -fsSL --retry 3 -o "$tmp/$asset" "https://github.com/$repo/releases/download/v$version/$asset"
        sha="$(sha256sum "$tmp/$asset" | cut -d' ' -f1)"
        recorded="$(jq -r --arg n "$asset" '.assets[] | select(.name == $n) | .digest // empty' <<<"$api" | sed 's/^sha256://')"
        if [ -z "$recorded" ]; then
            echo "warning: GitHub records no digest for $asset; hash is download-only" >&2
        elif [ "$recorded" != "$sha" ]; then
            echo "digest mismatch for $asset: downloaded $sha, GitHub $recorded" >&2; exit 1
        fi
        echo "$version $asset $sha" >> "$file"
        echo "added: $version $asset $sha"
    done
done
