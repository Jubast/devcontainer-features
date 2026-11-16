#!/usr/bin/env bash
# Maintainer tool: add a release's assets to src/<feature>/checksums.txt.
# usage: scripts/update-checksums.sh <herdr|herdr-core|gcm|shellcheck|codex> <version>...
# Hashes are computed from the downloaded assets and cross-checked against the digest
# GitHub records for them (GITHUB_TOKEN is used for the API if set), or for herdr-core
# against the sha256 in its release manifest. Review the diff.
set -euo pipefail
cd "$(dirname "$0")/.." || exit 1

[ "$#" -ge 2 ] || { sed -n '2,3p' "$0" | sed 's/^# //' >&2; exit 2; }
feature="$1"; shift

tag_prefix=v # release tags are <prefix><version>
case "$feature" in
    herdr) repo=herdrdev/herdr ;;
    herdr-core) ;; # released on releases.herdr.dev, not GitHub
    gcm) repo=git-ecosystem/git-credential-manager ;;
    shellcheck) repo=koalaman/shellcheck ;;
    codex) repo=openai/codex tag_prefix=rust-v ;;
    *) echo "Unknown feature: $feature" >&2; exit 2 ;;
esac

assets() { # version
    case "$feature" in
        herdr) echo herdr-linux-x86_64 herdr-linux-aarch64 ;;
        herdr-core) echo herdr-core-linux-x86_64.tar.gz herdr-core-linux-aarch64.tar.gz ;;
        gcm) echo "gcm-linux-x64-$1.deb" "gcm-linux-arm64-$1.deb" ;;
        shellcheck) echo "shellcheck-v$1.linux.x86_64.tar.xz" "shellcheck-v$1.linux.aarch64.tar.xz" ;;
        codex) echo codex-x86_64-unknown-linux-musl.tar.gz codex-aarch64-unknown-linux-musl.tar.gz ;;
    esac
}

# release_url VERSION: where the assets are downloaded from.
release_url() {
    case "$feature" in
        herdr-core) echo "https://releases.herdr.dev/core/$1" ;;
        *) echo "https://github.com/$repo/releases/download/$tag_prefix$1" ;;
    esac
}

# release_meta VERSION: the release's JSON with the recorded digests.
release_meta() {
    case "$feature" in
        herdr-core) curl -fsSL "$(release_url "$1")/manifest.json" ;;
        *) curl -fsSL ${GITHUB_TOKEN:+-H "Authorization: Bearer $GITHUB_TOKEN"} \
            "https://api.github.com/repos/$repo/releases/tags/$tag_prefix$1" ;;
    esac
}

# recorded_sha256 ASSET: the digest in the release JSON on stdin, if any.
recorded_sha256() {
    case "$feature" in
        herdr-core) jq -r --arg n "$1" '.targets[] | select(.url | endswith("/" + $n)) | .sha256 // empty' ;;
        *) jq -r --arg n "$1" '.assets[] | select(.name == $n) | .digest // empty' | sed 's/^sha256://' ;;
    esac
}

file="src/$feature/checksums.txt"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

for version in "$@"; do
    version="${version#v}"
    [[ "$version" =~ ^[0-9]+(\.[0-9]+){1,2}$ ]] || { echo "Invalid version: $version" >&2; exit 2; }
    meta="$(release_meta "$version")" \
        || { echo "Release $version of $feature not found (or API rate limited)." >&2; exit 1; }
    for asset in $(assets "$version"); do
        if grep -qE "^$version $asset " "$file" 2>/dev/null; then echo "skip (listed): $version $asset"; continue; fi
        curl -fsSL --retry 3 -o "$tmp/$asset" "$(release_url "$version")/$asset"
        sha="$(sha256sum "$tmp/$asset" | cut -d' ' -f1)"
        recorded="$(recorded_sha256 "$asset" <<<"$meta")"
        if [ -z "$recorded" ]; then
            echo "warning: no release digest is recorded for $asset; hash is download-only" >&2
        elif [ "$recorded" != "$sha" ]; then
            echo "digest mismatch for $asset: downloaded $sha, release $recorded" >&2; exit 1
        fi
        echo "$version $asset $sha" >> "$file"
        echo "added: $version $asset $sha"
    done
done
