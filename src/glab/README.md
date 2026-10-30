# glab (`glab`)

Installs the [GitLab CLI](https://gitlab.com/gitlab-org/cli) (`glab`).

```jsonc
"features": {
    "ghcr.io/jubast/devcontainer-features/glab:1": {}
}
```

## Options

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `version` | string | `latest` | Version to install, e.g. `1.126.0`. A leading `v` is optional. |

## Source and integrity

- Source: GitLab release asset `glab_<version>_linux_<amd64|arm64>.tar.gz`.
- Verified against the release's `checksums.txt`.

Architectures: amd64, arm64. See the [repository README](../../README.md) for the supply-chain policy.
