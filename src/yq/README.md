# yq (`yq`)

Installs [mikefarah/yq](https://github.com/mikefarah/yq) v4.

```jsonc
"features": {
    "ghcr.io/jubast/devcontainer-features/yq:1": {}
}
```

## Options

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `version` | string | `latest` | Version to install, e.g. `4.54.1`. A leading `v` is optional. |

## Source and integrity

- Source: GitHub release asset `yq_linux_<amd64|arm64>`.
- Verified against the SHA-256 column of the release's `checksums` (column located via `checksums_hashes_order`).

Architectures: amd64, arm64. Debian and Ubuntu based images only (needs `apt-get`). See the [repository README](../../README.md) for the supply-chain policy.
