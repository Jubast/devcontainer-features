# conftest (`conftest`)

Installs [Conftest](https://github.com/open-policy-agent/conftest).

```jsonc
"features": {
    "ghcr.io/jubast/devcontainer-features/conftest:1": {}
}
```

## Options

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `version` | string | `latest` | Version to install, e.g. `0.71.1`. A leading `v` is optional. |

## Source and integrity

- Source: GitHub release asset `conftest_<version>_Linux_<x86_64|arm64>.tar.gz`.
- Verified against the release's `checksums.txt`.

Architectures: amd64, arm64. Debian and Ubuntu based images only (needs `apt-get`). See the [repository README](../../README.md) for the supply-chain policy.
