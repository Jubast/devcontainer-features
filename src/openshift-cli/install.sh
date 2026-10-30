#!/usr/bin/env bash

# --- common (identical in every install.sh, enforced by scripts/lint.sh) ---
set -euo pipefail

[ "$(id -u)" -eq 0 ] || { echo "Must run as root." >&2; exit 1; }

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

download() { curl -fsSL --retry 3 -o "$2" "$1"; }

gh_api() { curl -fsSL --retry 3 ${GITHUB_TOKEN:+-H "Authorization: Bearer $GITHUB_TOKEN"} "$1"; }

# Newest release tag, from the redirect of a ".../releases/latest" URL (no API quota).
latest_tag() {
    curl -fsSI --retry 3 "$1" | tr -d '\r' | sed -n 's#^[Ll]ocation: .*/\(v[0-9][^/]*\)$#\1#p' | tail -n 1
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

# sha256 GitHub recorded for a release asset: gh_digest OWNER/REPO TAG ASSET.
gh_digest() {
    gh_api "https://api.github.com/repos/$1/releases/tags/$2" \
        | jq -r --arg n "$3" '.assets[] | select(.name == $n) | .digest // empty' | sed 's/^sha256://'
}
# --- end common ---

VERSION="${VERSION:-latest}"
# Mirror directory: "stable", "stable-4.16", "4.16.20", ... ("latest" means "stable").
if [ "$VERSION" = latest ]; then VERSION=stable; fi
[[ "$VERSION" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || { echo "Invalid version: ${VERSION}" >&2; exit 1; }
case "$(uname -m)" in
    x86_64|amd64) ARCH_PART="" ;;
    aarch64|arm64) ARCH_PART="-arm64" ;;
    *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

# Channel directories (stable, stable-4.16) list "openshift-client-linux.tar.gz";
# exact-version directories (4.16.20) only list "openshift-client-linux-4.16.20.tar.gz".
if [[ "$VERSION" =~ ^[0-9] ]]; then
    ASSET="openshift-client-linux${ARCH_PART}-${VERSION}.tar.gz"
else
    ASSET="openshift-client-linux${ARCH_PART}.tar.gz"
fi

ensure_pkgs curl ca-certificates tar
BASE="https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${VERSION}"

echo "Installing oc from ${BASE}/${ASSET}"
download "${BASE}/${ASSET}" "${TMP_DIR}/${ASSET}"
download "${BASE}/sha256sum.txt" "${TMP_DIR}/sha256sum.txt"
verify_sha256 "${TMP_DIR}/${ASSET}" "$(checksum_of "${TMP_DIR}/sha256sum.txt" "$ASSET")"

tar -xzf "${TMP_DIR}/${ASSET}" -C "$TMP_DIR" oc
install -m 0755 "${TMP_DIR}/oc" /usr/local/bin/oc
oc version --client
