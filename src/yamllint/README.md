# yamllint (`yamllint`)

Installs [yamllint](https://github.com/adrienverge/yamllint).

```jsonc
"features": {
    "ghcr.io/jubast/devcontainer-features/yamllint:1": {}
}
```

## Options

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `version` | string | `latest` | Version to install, e.g. `1.37.1`. `latest` uses the distro package. |

## Source and integrity

- Source: `latest`: the distro `yamllint` apt package. Pinned: `pip install yamllint==<version>` into `/opt/yamllint`.
- `latest` is the distro package, so apt's signed archive covers it (and it can be older than upstream). A pinned version is installed from PyPI over TLS with **no checksum verification** (upstream publishes none).

## Notes

A pinned install adds `python3` and `python3-venv` if missing and symlinks `/usr/local/bin/yamllint`.

Architectures: amd64, arm64. See the [repository README](../../README.md) for the supply-chain policy.
