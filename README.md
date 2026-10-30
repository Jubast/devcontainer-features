# devcontainer-features

Dev container features for tools that Microsoft's official [`devcontainers/features`](https://github.com/devcontainers/features) do not cover.

## Policy

Consume only Microsoft's official features (`ghcr.io/devcontainers/features/*`). Everything else is implemented here, so no third-party feature repository can inject code into our images. Every install script is short, readable and verifies what it downloads.

## Features

Published as `ghcr.io/jubast/devcontainer-features/<id>:1`. All take a `version` option (default `latest`, or a pinned version) and support amd64 and arm64.

| Id | Installs | Integrity check |
| --- | --- | --- |
| [`conftest`](src/conftest) | Conftest | upstream `checksums.txt` |
| [`gcm`](src/gcm) | Git Credential Manager | committed `checksums.txt` (no upstream checksums) |
| [`glab`](src/glab) | GitLab CLI | upstream `checksums.txt` |
| [`herdr`](src/herdr) | herdr | committed `checksums.txt` (no upstream checksums) |
| [`kubeconform`](src/kubeconform) | kubeconform | upstream `CHECKSUMS` |
| [`openshift-cli`](src/openshift-cli) | `oc` from mirror.openshift.com | mirror `sha256sum.txt` |
| [`pluto`](src/pluto) | Pluto | upstream `checksums.txt` |
| [`shellcheck`](src/shellcheck) | ShellCheck | `latest`: apt (signed); pinned: committed `checksums.txt` |
| [`yamllint`](src/yamllint) | yamllint | `latest`: apt (signed); pinned: PyPI over TLS only |
| [`yq`](src/yq) | mikefarah/yq v4 | upstream `checksums` (SHA-256 column) |

Usage:

```jsonc
"features": {
    "ghcr.io/jubast/devcontainer-features/yq:1": {},
    "ghcr.io/jubast/devcontainer-features/conftest:1": { "version": "0.71.1" }
}
```

Not here, use the official features: kubectl/helm, python, node, dotnet, github-cli, azure-cli, common-utils, copilot-cli.

## Supply chain

- **Checksums.** Each install downloads the upstream checksum file next to the artifact, compares sha256 and aborts on mismatch or a missing entry. Where upstream publishes none (herdr, gcm, pinned shellcheck) the sha256 values are committed in the feature's `checksums.txt` and only listed versions can be installed; yamllint pinned to a version has no check beyond TLS. Each feature README states which applies.
- **Limits.** The checksum file comes from the same release as the artifact, so this catches corruption and swapped assets, not a compromised upstream release. Pin versions and review upgrades to limit that exposure. Signatures (sigstore, GPG) are not verified.
- **Pinning.** Set `version` to an exact release (`"version": "0.71.1"`; `oc`: a mirror directory such as `4.16.20`). `latest` resolves at build time for features with upstream checksums (newest release), and to the newest listed version for herdr and gcm; `shellcheck` and `yamllint` `latest` mean the distro apt package.
- **No `curl | bash`.** Scripts are downloaded to a temp dir, verified, then installed; the `version` input is validated before it reaches a URL.
- **CI.** Workflows use only `actions/*` and `devcontainers/*`, pinned to full commit SHAs, with `contents: read`; `packages: write` only on the release job. The devcontainer CLI is pinned to an exact version. `scripts/lint.sh` enforces the workflow rules.
- **Shipped checksums.** For herdr, gcm and pinned shellcheck, `src/<id>/checksums.txt` lists `<version> <asset> <sha256>`. `latest` there means the newest *listed* version, a deliberate choice: updating is a reviewed PR that runs `scripts/update-checksums.sh <id> <version>` (hashes the downloaded assets, cross-checks GitHub's recorded digest; maintainers only, may use `GITHUB_TOKEN`). No install script calls the GitHub API.

## Migrating the workspace devcontainer

After publishing, official features stay and the rest becomes:

```jsonc
"features": {
    "ghcr.io/jubast/devcontainer-features/herdr:1": {},
    "ghcr.io/jubast/devcontainer-features/gcm:1": {},
    "ghcr.io/jubast/devcontainer-features/glab:1": {},
    "ghcr.io/jubast/devcontainer-features/openshift-cli:1": {},
    "ghcr.io/jubast/devcontainer-features/kubeconform:1": {},
    "ghcr.io/jubast/devcontainer-features/pluto:1": {},
    "ghcr.io/jubast/devcontainer-features/yq:1": {},
    "ghcr.io/jubast/devcontainer-features/conftest:1": {},
    "ghcr.io/jubast/devcontainer-features/shellcheck:1": {},
    "ghcr.io/jubast/devcontainer-features/yamllint:1": {},
    "ghcr.io/devcontainers/features/common-utils:2": { "installZsh": false, "installOhMyZsh": false, "upgradePackages": true },
    "ghcr.io/devcontainers/features/python:1": {},
    "ghcr.io/devcontainers/features/node:2": {},
    "ghcr.io/devcontainers/features/dotnet:2": { "version": "10.0" },
    "ghcr.io/devcontainers/features/github-cli:1": {},
    "ghcr.io/devcontainers/features/kubectl-helm-minikube:1": { "minikube": "none" },
    "ghcr.io/devcontainers/features/azure-cli:1": { "extensions": "azure-devops" },
    "ghcr.io/devcontainers/features/copilot-cli:1": {}
}
```

Remove the `./features/*` directory and these third-party entries: `eitsupi/devcontainer-features/jq-likes`, `dhoeric/features/conftest`, `devcontainers-extra/features/shellcheck`, `devcontainers-extra/features/yamllint`. `claude-code` (`ghcr.io/anthropics/devcontainer-features`) has no replacement here yet. The old `jq-likes` also installed `jq`; `common-utils` provides it. herdr no longer installs the herdr-reviewr plugin.

## Development

```sh
scripts/lint.sh                                   # offline checks
devcontainer features test -f yq .                # needs docker (CI runs it)
devcontainer features test --global-scenarios-only .
```

Add a feature:

1. `src/<id>/devcontainer-feature.json`, `install.sh` (copy the `# --- common ---` block from an existing feature) and `README.md`.
2. `test/<id>/test.sh`, `pinned.sh`, `scenarios.json`; add the id to the `test.yaml` matrix and `test/_global`.
3. Run `scripts/lint.sh`.

Release: bump `version` in the changed features' `devcontainer-feature.json`, merge to `main`, then tag and push:

```sh
git tag v1.1.0 && git push origin v1.1.0
```

The tag runs the release workflow and publishes every feature to `ghcr.io/jubast/devcontainer-features`. New packages are private by default: set them to public in the GitHub package settings once.
