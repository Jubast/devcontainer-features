# herdr-core (`herdr-core`)

Installs [herdr-core](https://github.com/herdrdev/herdr-core) (`hc`), the terminal core behind the [herdr app](https://github.com/herdrdev/herdr-app). It is a different program from the [`herdr`](../herdr) TUI feature: `hc` keeps terminals and agents alive and draws nothing; the app is the client. Both can be installed side by side.

```jsonc
"features": {
    "ghcr.io/jubast/devcontainer-features/herdr-core:1": {}
}
```

## Options

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `version` | string | `latest` | Version to install, e.g. `0.1.21`. A leading `v` is optional. `latest` is the newest version listed in [`checksums.txt`](checksums.txt), not the newest upstream release. |

## Use

Installs `herdr-core` and, unless an `hc` already exists, an `hc` symlink to it in `/usr/local/bin`. No core runs after the install: the first `hc` command, or a client's `hc connect`, starts one per user and session.

To attach the herdr app, add the container as an SSH machine (the app runs `ssh <host> hc connect`), so the container needs an SSH server, for example the official [`sshd`](https://github.com/devcontainers/features/tree/main/src/sshd) feature. Core runs commands with the account's full access and has no authentication of its own, see its [security notes](https://github.com/herdrdev/herdr-core/blob/master/docs/security.md).

Update by changing `version` and rebuilding the container.

## Source and integrity

- Source: `https://releases.herdr.dev/core/<version>/herdr-core-linux-<x86_64|aarch64>.tar.gz` (herdr-core publishes no GitHub releases).
- **No independent checksum.** The release manifest on the same server carries a sha256, which upstream itself only checks over HTTPS. The sha256 of each supported release is committed in [`checksums.txt`](checksums.txt) (computed from the downloaded asset and cross-checked against the manifest). The install fails for a version that is not listed. Add one with `scripts/update-checksums.sh herdr-core <version>` in a reviewed PR.

Architectures: amd64, arm64. Debian and Ubuntu based images only (needs `apt-get`). See the [repository README](../../README.md) for the supply-chain policy.
