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
| `version` | string | `latest` | Version to install, e.g. `3.0.2`. A leading `v` is optional. `latest` is the newest version listed in [`checksums.txt`](checksums.txt), not the newest upstream release. |

## Source and integrity

- Source: GitHub release asset `gcm-linux-<x64|arm64>-<version>.deb`.
- **No upstream checksum file.** The sha256 of each supported release is committed in [`checksums.txt`](checksums.txt) (computed from the downloaded asset and cross-checked against GitHub's recorded digest). The install fails for a version that is not listed. Add one with `scripts/update-checksums.sh gcm <version>` in a reviewed PR.

## Notes

Requires `git`, which is installed from apt if missing (bare Debian images have none). Installed with `apt-get install` so dependencies are resolved. The ICU runtime (`libicuNN`, picked from apt for the distro) is installed explicitly because .NET aborts without it on Debian images. Run `git-credential-manager configure` yourself.

Architectures: amd64, arm64. See the [repository README](../../README.md) for the supply-chain policy.
