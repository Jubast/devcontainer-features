# herdr (`herdr`)

Installs the [herdr](https://github.com/herdrdev/herdr) CLI.

```jsonc
"features": {
    "ghcr.io/jubast/devcontainer-features/herdr:1": {}
}
```

## Options

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `version` | string | `latest` | Version to install, e.g. `0.9.5`. A leading `v` is optional. `latest` is the newest version listed in [`checksums.txt`](checksums.txt), not the newest upstream release. |

## Source and integrity

- Source: GitHub release asset `herdr-linux-<x86_64|aarch64>`.
- **No upstream checksum file.** The sha256 of each supported release is committed in [`checksums.txt`](checksums.txt) (computed from the downloaded asset and cross-checked against GitHub's recorded digest). The install fails for a version that is not listed. Add one with `scripts/update-checksums.sh herdr <version>` in a reviewed PR.

Architectures: amd64, arm64. See the [repository README](../../README.md) for the supply-chain policy.
