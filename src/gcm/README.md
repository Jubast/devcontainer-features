# Git Credential Manager (`gcm`)

Installs [Git Credential Manager](https://github.com/git-ecosystem/git-credential-manager) (`git-credential-manager`).

```jsonc
"features": {
    "ghcr.io/jubast/devcontainer-features/gcm:1": {}
}
```

## Options

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `version` | string | `latest` | Version to install, e.g. `3.0.2`. A leading `v` is optional. |

## Source and integrity

- Source: GitHub release asset `gcm-linux-<x64|arm64>-<version>.deb`.
- **No upstream checksum file.** The `.deb` is checked against the sha256 GitHub records for it (`digest` in the releases API). This catches corruption and later asset swaps, not a compromised publisher. Releases that predate GitHub digests cannot be installed.

## Notes

Installed with `apt-get install` so dependencies (e.g. libicu) are resolved. Run `git-credential-manager configure` yourself.

Architectures: amd64, arm64. See the [repository README](../../README.md) for the supply-chain policy.
