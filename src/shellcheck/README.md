# shellcheck (`shellcheck`)

Installs [ShellCheck](https://github.com/koalaman/shellcheck).

```jsonc
"features": {
    "ghcr.io/jubast/devcontainer-features/shellcheck:1": {}
}
```

## Options

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `version` | string | `latest` | Version to install, e.g. `0.11.0`. `latest` uses the distro package. |

## Source and integrity

- Source: `latest`: the distro `shellcheck` apt package. Pinned: GitHub release asset `shellcheck-v<version>.linux.<x86_64|aarch64>.tar.xz`.
- `latest` is the distro package, so apt's signed archive covers it (and it can be older than upstream). A pinned version has **no upstream checksum file**: the tarball is checked against the sha256 GitHub records for it (`digest` in the releases API). This catches corruption and later asset swaps, not a compromised publisher.

## Notes

Pin a version if you need newer than the distro package.

Architectures: amd64, arm64. See the [repository README](../../README.md) for the supply-chain policy.
