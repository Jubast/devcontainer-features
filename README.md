# devcontainer-features

Dev container features for tools that Microsoft's official [`devcontainers/features`](https://github.com/devcontainers/features) do not cover.

## Policy

This repository consumes no third-party features. Every installer is implemented here and verifies what it downloads wherever upstream makes that possible (see [Supply chain](#supply-chain)).

## Features

Published as `ghcr.io/jubast/devcontainer-features/<id>:1`. All take a `version` option (default `latest`, or a pinned version) and support amd64 and arm64 on Debian and Ubuntu based images (they need `apt-get`; other distributions are not supported).

| Id | Installs | `latest` means | Integrity check |
| --- | --- | --- | --- |
| [`claude`](src/claude) | Claude Code, plus optional marketplaces, plugins and settings | newest upstream release | release `manifest.json` |
| [`codex`](src/codex) | Codex CLI, plus optional marketplaces, plugins and settings | newest version listed in the shipped `checksums.txt` | shipped `checksums.txt` |
| [`conftest`](src/conftest) | Conftest | newest upstream release | upstream `checksums.txt` |
| [`copilot`](src/copilot) | GitHub Copilot CLI, plus optional marketplaces, plugins and settings | newest upstream release | upstream `SHA256SUMS.txt` |
| [`gcm`](src/gcm) | Git Credential Manager | newest version listed in the shipped `checksums.txt` | shipped `checksums.txt` |
| [`glab`](src/glab) | GitLab CLI | newest upstream release | upstream `checksums.txt` |
| [`herdr`](src/herdr) | herdr, plus optional plugins | newest version listed in the shipped `checksums.txt` | shipped `checksums.txt` |
| [`kubeconform`](src/kubeconform) | kubeconform | newest upstream release | upstream `CHECKSUMS` |
| [`openshift-cli`](src/openshift-cli) | `oc` from mirror.openshift.com | the mirror's `stable` channel | mirror `sha256sum.txt` |
| [`pluto`](src/pluto) | Pluto | newest upstream release | upstream `checksums.txt` |
| [`shellcheck`](src/shellcheck) | ShellCheck | the distro apt package (can be older than upstream) | `latest`: signed apt archive; pinned: shipped `checksums.txt` |
| [`yamllint`](src/yamllint) | yamllint | the distro apt package (can be older than upstream) | `latest`: signed apt archive; pinned: none (PyPI over TLS) |
| [`yq`](src/yq) | mikefarah/yq v4 | newest upstream release | upstream `checksums` (SHA-256 column) |

Usage:

```jsonc
"features": {
    "ghcr.io/jubast/devcontainer-features/yq:1": {},
    "ghcr.io/jubast/devcontainer-features/conftest:1": { "version": "0.71.1" }
}
```

Not here, use the official features: kubectl/helm, python, node, dotnet, github-cli, azure-cli, common-utils.

## Agent harness features

`claude`, `copilot` and `codex` install an agent CLI and share the options `marketplaces`, `plugins` and `settings`, applied on every container create; see each feature's README for details. They depend on this repository's `yq` feature.

## Supply chain

- **Checksums.** Each install downloads the upstream checksum file next to the artifact, compares sha256 and aborts on a mismatch or a missing entry. Where upstream publishes none (herdr, gcm, codex, pinned shellcheck), the sha256 values are committed in the feature's `checksums.txt` and only listed versions can be installed. The one exception is yamllint pinned to a version, which comes from PyPI over TLS with no hash check and unpinned dependencies; use the distro package (`latest`) if that matters. Each feature README states which applies.
- **Limits.** An upstream checksum file comes from the same release as the artifact, so it catches corruption and swapped assets, not a compromised upstream release. Pin versions and review upgrades to limit that exposure. Signatures (sigstore, GPG) are not verified.
- **Pinning.** Set `version` to an exact release (`"version": "0.71.1"`; for `oc` a mirror directory such as `4.16.20`). To pin the feature itself, use its digest instead of a tag: `ghcr.io/jubast/devcontainer-features/yq@sha256:<digest>` (the digest is shown on the package page; the dev container CLI can also record it in `devcontainer-lock.json`).
- **Shipped checksums.** For herdr, gcm, codex and pinned shellcheck, `src/<id>/checksums.txt` lists `<version> <asset> <sha256>`. For herdr, gcm and codex `latest` means the newest *listed* version: updating is a reviewed PR that runs `scripts/update-checksums.sh <id> <version>` (hashes the downloaded assets and cross-checks the digest GitHub records; maintainers only, may use `GITHUB_TOKEN`). No install script calls the GitHub API.
- **Transport.** Downloads use HTTPS only (also across redirects) and TLS 1.2 or newer. Nothing is piped into a shell: files are downloaded to a temp dir, verified, then installed. The `version` input is validated before it reaches a URL.
- **CI.** Workflows use only `actions/*` and `devcontainers/*`, pinned to full commit SHAs, with `contents: read`; `packages: write` only on the publish job. The devcontainer CLI is pinned to an exact version. `scripts/lint.sh` enforces these rules.

Report a vulnerability as described in [SECURITY.md](SECURITY.md).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the checks, adding a feature and maintainer settings.

## Release

A feature is published only when its `version` in `devcontainer-feature.json` is new; the publisher skips versions that already exist in the registry. `scripts/lint.sh` fails if `src/<id>/` changed since the latest `v*` tag without a higher version (README-only edits are exempt; they ship with the next release, since the README is part of the published package).

The repository tag is independent of the feature versions: use the next unused `vX.Y.Z`. The latest tag is `v1.0.0`, so `v1.0.1` is the next release.

1. Bump `version` in each changed feature only (a patch release for a fix, e.g. `1.0.1` to `1.0.2`).
2. Merge to `main` with a green CI run.
3. Tag the `main` commit with the next unused version and push the tag:

```sh
git tag vX.Y.Z && git push origin vX.Y.Z
```

The release workflow checks that the tagged commit is on `main` and that lint passes, then publishes the features whose version changed to `ghcr.io/jubast/devcontainer-features`. New packages are private by default: set them to public in the GitHub package settings once. The gate has limits, see [SECURITY.md](SECURITY.md#release-gate).
