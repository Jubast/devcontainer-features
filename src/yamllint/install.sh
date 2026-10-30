#!/usr/bin/env bash

# --- common (identical in every install.sh, enforced by scripts/lint.sh) ---
set -Eeuo pipefail
trap 'echo "ERROR: install.sh line ${LINENO}: ${BASH_COMMAND}" >&2' ERR
export DEBIAN_FRONTEND=noninteractive

[ "$(id -u)" -eq 0 ] || { echo "Must run as root." >&2; exit 1; }
command -v apt-get >/dev/null || { echo "Only Debian and Ubuntu based images are supported." >&2; exit 1; }

FEATURE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

ensure_pkgs() {
    local p missing=()
    for p in "$@"; do dpkg -s "$p" >/dev/null 2>&1 || missing+=("$p"); done
    [ "${#missing[@]}" -eq 0 ] && return 0
    apt-get update -y
    apt-get install -y --no-install-recommends "${missing[@]}"
    rm -rf /var/lib/apt/lists/*
}

# HTTPS only (also across redirects), TLS 1.2 or newer.
CURL=(curl -fsS --proto '=https' --proto-redir '=https' --tlsv1.2 --retry 3)

download() { "${CURL[@]}" -L -o "$2" "$1"; }

# Newest release tag, from the redirect of a ".../releases/latest" URL (no API quota).
latest_tag() {
    "${CURL[@]}" -I "$1" | tr -d '\r' | sed -n 's#^[Ll]ocation: .*/\(v[0-9][^/]*\)$#\1#p' | tail -n 1
}

# Accepts 1.2.3 or v1.2.3 and prints v1.2.3; rejects anything else.
normalize_tag() {
    [[ "$1" =~ ^v?[0-9]+(\.[0-9]+){1,2}$ ]] || { echo "Invalid version: $1" >&2; exit 1; }
    echo "v${1#v}"
}

# resolve_tag VERSION LATEST_URL: "latest" -> newest release tag, else a normalized tag.
resolve_tag() {
    local t
    if [ "$1" != latest ]; then normalize_tag "$1"; return; fi
    t="$(latest_tag "$2")"
    [ -n "$t" ] || { echo "Could not resolve the latest version." >&2; exit 1; }
    echo "$t"
}

# Hash for NAME in a "<sha256>  <name>" checksums file.
checksum_of() { awk -v n="$2" '$2 == n || $2 == "*" n { print $1; exit }' "$1"; }

# verify_sha256 FILE EXPECTED: abort the install on mismatch or empty EXPECTED.
verify_sha256() {
    local actual
    [[ "$2" =~ ^[0-9a-f]{64}$ ]] || { echo "No sha256 found for $(basename "$1")." >&2; exit 1; }
    actual="$(sha256sum "$1" | cut -d' ' -f1)"
    [ "$actual" = "$2" ] || { echo "sha256 mismatch for $(basename "$1"): expected $2, got $actual" >&2; exit 1; }
    echo "sha256 ok: $(basename "$1")"
}

# Features without upstream checksums ship "<version> <asset> <sha256>" lines in checksums.txt.
listed_versions() { awk '$1 !~ /^#/ && NF { print $1 }' "$FEATURE_DIR/checksums.txt" | sort -uV; }

# shipped_sha256 VERSION ASSET: the shipped hash, or abort naming the listed versions.
shipped_sha256() {
    local h
    h="$(awk -v v="$1" -v a="$2" '$1 == v && $2 == a { print $3; exit }' "$FEATURE_DIR/checksums.txt")"
    [ -n "$h" ] || { echo "No checksum shipped for $2 (version $1). Listed versions: $(listed_versions | tr '\n' ' ')" >&2; exit 1; }
    echo "$h"
}
# --- end common ---

VERSION="${VERSION:-latest}"

if [ "$VERSION" = latest ]; then
    # Distro package: signed by the distro archive.
    ensure_pkgs yamllint
    yamllint --version
    exit 0
fi

# Pinned version: PyPI into an isolated venv (no upstream checksum to verify); pip needs CA certificates.
[[ "$VERSION" =~ ^[0-9]+(\.[0-9]+){1,2}$ ]] || { echo "Invalid version: ${VERSION}" >&2; exit 1; }
ensure_pkgs ca-certificates python3 python3-venv
python3 -m venv /opt/yamllint
/opt/yamllint/bin/pip install --no-cache-dir "yamllint==${VERSION}"
ln -sf /opt/yamllint/bin/yamllint /usr/local/bin/yamllint
yamllint --version
