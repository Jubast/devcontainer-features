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
case "$(uname -m)" in
    x86_64|amd64) ARCH=x64 ;;
    aarch64|arm64) ARCH=arm64 ;;
    *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

# "latest" is the newest version listed in checksums.txt, not the newest upstream release.
if [ "$VERSION" = latest ]; then VERSION="$(listed_versions | tail -n 1)"; fi
VERSION="$(normalize_tag "$VERSION")"
VERSION="${VERSION#v}"
ASSET="gcm-linux-${ARCH}-${VERSION}.deb"

# git-credential-manager needs git on the PATH, even for --version.
ensure_pkgs curl ca-certificates git
EXPECTED="$(shipped_sha256 "$VERSION" "$ASSET")"

echo "Installing git-credential-manager ${VERSION} (${ARCH})"
download "https://github.com/git-ecosystem/git-credential-manager/releases/download/v${VERSION}/${ASSET}" "${TMP_DIR}/${ASSET}"
verify_sha256 "${TMP_DIR}/${ASSET}" "$EXPECTED"

# .NET aborts without the ICU runtime (libicuNN, NN depends on the distro), which
# Debian base images do not ship. Pick the newest installable one from apt.
apt-get update -y
ICU_PKG=""
while read -r pkg; do
    cand="$(apt-cache policy "$pkg" | awk '/Candidate:/ { print $2 }')"
    if [ -n "$cand" ] && [ "$cand" != "(none)" ]; then ICU_PKG="$pkg"; break; fi
done < <(apt-cache search --names-only '^libicu[0-9]+$' | awk '{ print $1 }' | sort -rV)
[ -n "$ICU_PKG" ] || { echo "No libicu package available from apt." >&2; exit 1; }

# apt also resolves the package's other dependencies, which dpkg -i does not.
apt-get install -y --no-install-recommends "$ICU_PKG" "${TMP_DIR}/${ASSET}"
rm -rf /var/lib/apt/lists/*
git-credential-manager --version
