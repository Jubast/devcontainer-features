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

BIN_DIR=/usr/local/bin
case "$(uname -m)" in
    x86_64|amd64) ARCH=amd64; ARCH_X=x86_64; OC_ARCH_PART="" ;;
    aarch64|arm64) ARCH=arm64; ARCH_X=arm64; OC_ARCH_PART="-arm64" ;;
    *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

# Supported extensions; each has an install_<name> function below.
EXTENSIONS_SUPPORTED=(conftest helm kubeconform kustomize oc pluto)

# fetch_bin NAME BASE ASSET SUMS_URL MEMBER: download ASSET from BASE, verify it against the
# "<sha256>  <asset>" file at SUMS_URL, install MEMBER of the tarball as BIN_DIR/NAME.
fetch_bin() {
    local name="$1" base="$2" asset="$3" sums_url="$4" member="$5"
    download "${base}/${asset}" "${TMP_DIR}/${asset}"
    download "$sums_url" "${TMP_DIR}/${asset}.sums"
    verify_sha256 "${TMP_DIR}/${asset}" "$(checksum_of "${TMP_DIR}/${asset}.sums" "$asset")"
    tar -xzf "${TMP_DIR}/${asset}" -C "$TMP_DIR" "$member"
    install -m 0755 "${TMP_DIR}/${member}" "${BIN_DIR}/${name}"
}

# install_kubectl VERSION: dl.k8s.io publishes a bare sha256 next to each binary.
install_kubectl() {
    local tag base
    if [ "$1" = latest ]; then
        tag="$("${CURL[@]}" -L https://dl.k8s.io/release/stable.txt)"
        [[ "$tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "Could not resolve the latest kubectl version." >&2; exit 1; }
    else
        tag="$(normalize_tag "$1")"
    fi
    base="https://dl.k8s.io/release/${tag}/bin/linux/${ARCH}"
    echo "Installing kubectl ${tag} (${ARCH})"
    download "${base}/kubectl" "${TMP_DIR}/kubectl"
    download "${base}/kubectl.sha256" "${TMP_DIR}/kubectl.sha256"
    verify_sha256 "${TMP_DIR}/kubectl" "$(awk '{ print $1; exit }' "${TMP_DIR}/kubectl.sha256")"
    install -m 0755 "${TMP_DIR}/kubectl" "${BIN_DIR}/kubectl"
    kubectl version --client
}

install_helm() {
    local tag asset
    tag="$(resolve_tag "$1" https://github.com/helm/helm/releases/latest)"
    asset="helm-${tag}-linux-${ARCH}.tar.gz"
    echo "Installing helm ${tag} (${ARCH})"
    fetch_bin helm https://get.helm.sh "$asset" "https://get.helm.sh/${asset}.sha256sum" "linux-${ARCH}/helm"
    helm version --short
}

install_kustomize() {
    local tag base asset
    # Release tags look like kustomize/v5.8.3.
    tag="$(resolve_tag "$1" https://github.com/kubernetes-sigs/kustomize/releases/latest)"
    base="https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2F${tag}"
    asset="kustomize_${tag}_linux_${ARCH}.tar.gz"
    echo "Installing kustomize ${tag} (${ARCH})"
    fetch_bin kustomize "$base" "$asset" "${base}/checksums.txt" kustomize
    kustomize version
}

install_kubeconform() {
    local tag base
    tag="$(resolve_tag "$1" https://github.com/yannh/kubeconform/releases/latest)"
    base="https://github.com/yannh/kubeconform/releases/download/${tag}"
    echo "Installing kubeconform ${tag} (${ARCH})"
    fetch_bin kubeconform "$base" "kubeconform-linux-${ARCH}.tar.gz" "${base}/CHECKSUMS" kubeconform
    kubeconform -v
}

install_pluto() {
    local tag base
    tag="$(resolve_tag "$1" https://github.com/FairwindsOps/pluto/releases/latest)"
    base="https://github.com/FairwindsOps/pluto/releases/download/${tag}"
    echo "Installing pluto ${tag} (${ARCH})"
    fetch_bin pluto "$base" "pluto_${tag#v}_linux_${ARCH}.tar.gz" "${base}/checksums.txt" pluto
    pluto version
}

install_conftest() {
    local tag base
    tag="$(resolve_tag "$1" https://github.com/open-policy-agent/conftest/releases/latest)"
    base="https://github.com/open-policy-agent/conftest/releases/download/${tag}"
    echo "Installing conftest ${tag} (${ARCH_X})"
    fetch_bin conftest "$base" "conftest_${tag#v}_Linux_${ARCH_X}.tar.gz" "${base}/checksums.txt" conftest
    conftest --version
}

# install_oc VERSION: a mirror directory ("stable", "stable-4.16", "4.16.20"); "latest" means "stable".
install_oc() {
    local dir="$1" asset base
    if [ "$dir" = latest ]; then dir=stable; fi
    [[ "$dir" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || { echo "Invalid oc version: ${dir}" >&2; exit 1; }
    # Channel directories list "openshift-client-linux.tar.gz"; exact-version directories
    # only list "openshift-client-linux-<version>.tar.gz".
    if [[ "$dir" =~ ^[0-9] ]]; then
        asset="openshift-client-linux${OC_ARCH_PART}-${dir}.tar.gz"
    else
        asset="openshift-client-linux${OC_ARCH_PART}.tar.gz"
    fi
    base="https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${dir}"
    echo "Installing oc from ${base}/${asset}"
    fetch_bin oc "$base" "$asset" "${base}/sha256sum.txt" oc
    oc version --client
}

# Parse and validate every entry before installing anything.
requested=()
IFS=',' read -r -a entries <<< "${EXTENSIONS:-}"
for entry in "${entries[@]}"; do
    entry="${entry//[[:space:]]/}"
    [ -n "$entry" ] || continue
    name="${entry%%:*}"
    if [[ " ${EXTENSIONS_SUPPORTED[*]} " != *" ${name} "* ]]; then
        echo "Unknown extension '${name}'. Supported: ${EXTENSIONS_SUPPORTED[*]}" >&2
        exit 1
    fi
    if [[ "$entry" == *:* ]]; then ext_version="${entry#*:}"; else ext_version=latest; fi
    [ -n "$ext_version" ] || { echo "Empty version for extension '${name}'." >&2; exit 1; }
    requested+=("${name}:${ext_version}")
done

ensure_pkgs curl ca-certificates tar
install_kubectl "${VERSION:-latest}"
for entry in "${requested[@]}"; do
    "install_${entry%%:*}" "${entry#*:}"
done
