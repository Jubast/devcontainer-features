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
| `version` | string | `latest` | Version to install, e.g. `0.9.5`. A leading `v` is optional. |

## Source and integrity

- Source: GitHub release asset `herdr-linux-<x86_64|aarch64>`.
- **No upstream checksum file.** The asset is checked against the sha256 GitHub records for it (`digest` in the releases API). This catches corruption and later asset swaps, not a compromised publisher. Releases that predate GitHub digests cannot be installed.

## Notes

If `_REMOTE_USER` is a non-root user, a default `~/.config/herdr/config.toml` is copied in unless one exists. The herdr-reviewr plugin is not installed.

Architectures: amd64, arm64. See the [repository README](../../README.md) for the supply-chain policy.
