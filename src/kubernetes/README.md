# Kubernetes tools (`kubernetes`)

Installs `kubectl`, plus the extensions you list.

```jsonc
"features": {
    "ghcr.io/jubast/devcontainer-features/kubernetes:1": {
        "extensions": "helm,kustomize,oc:stable-4.16"
    }
}
```

## Options

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `version` | string | `latest` | kubectl version, e.g. `1.31.0`. `latest` is the current stable release. A leading `v` is optional. |
| `extensions` | string | empty | Comma-separated extension names; `name:version` pins one. Empty installs none. |

## Extensions

The set is fixed. An unknown name fails the install before anything is installed; no tool is looked up by name.

| Extension | Installs | `latest` means | Version format | Integrity check |
| --- | --- | --- | --- | --- |
| `conftest` | Conftest | newest upstream release | `0.71.1` | release `checksums.txt` |
| `helm` | Helm | newest upstream release | `3.16.2` | `.sha256sum` next to the archive on get.helm.sh |
| `kubeconform` | kubeconform | newest upstream release | `0.6.7` | release `CHECKSUMS` |
| `kustomize` | Kustomize | newest upstream release | `5.4.3` | release `checksums.txt` |
| `oc` | OpenShift CLI | the mirror's `stable` channel | mirror directory: `stable-4.16`, `4.16.20` | mirror `sha256sum.txt` |
| `pluto` | Pluto | newest upstream release | `5.24.4` | release `checksums.txt` |

A leading `v` is optional on every version except `oc`. Examples: `"extensions": "helm:3.16.2,kubeconform"`, `"version": "1.31.0"`.

## Source and integrity

- kubectl: the binary from `dl.k8s.io`, verified against the `kubectl.sha256` next to it. `latest` reads `dl.k8s.io/release/stable.txt`.
- Extensions: see the table. GitHub-hosted tools resolve `latest` from the `releases/latest` redirect, not the API.
- The mirror's GPG signature (`oc`) and sigstore signatures are not checked.
- Only `oc` is taken from the OpenShift archive (not its bundled `kubectl`).

Architectures: amd64, arm64. Debian and Ubuntu based images only (needs `apt-get`). See the [repository README](../../README.md) for the supply-chain policy.
