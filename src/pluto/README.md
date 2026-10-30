# pluto (`pluto`)

Installs [Pluto](https://github.com/FairwindsOps/pluto), the deprecated Kubernetes API detector.

```jsonc
"features": {
    "ghcr.io/jubast/devcontainer-features/pluto:1": {}
}
```

## Options

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `version` | string | `latest` | Version to install, e.g. `5.24.4`. A leading `v` is optional. |

## Source and integrity

- Source: GitHub release asset `pluto_<version>_linux_<amd64|arm64>.tar.gz`.
- Verified against the release's `checksums.txt`. The published sigstore bundles are not verified.

Architectures: amd64, arm64. See the [repository README](../../README.md) for the supply-chain policy.
