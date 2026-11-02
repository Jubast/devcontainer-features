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
| `plugins` | string | empty | Comma-separated [herdr plugins](https://herdr.dev/docs/plugins/) to install, as GitHub `owner/repo[/subdir][@ref]`. Blank entries are ignored; the install fails if a plugin cannot be installed. Installed for the container's remote user. |

```jsonc
"herdr": { "plugins": "ogulcancelik/herdr-plugin-examples/agent-telegram-notify@<commit-sha>" }
```

## Source and integrity

- Source: GitHub release asset `herdr-linux-<x86_64|aarch64>`.
- **No upstream checksum file.** The sha256 of each supported release is committed in [`checksums.txt`](checksums.txt) (computed from the downloaded asset and cross-checked against GitHub's recorded digest). The install fails for a version that is not listed. Add one with `scripts/update-checksums.sh herdr <version>` in a reviewed PR.
- **Plugins are not verified by this feature.** `herdr plugin install --yes` clones the plugin from GitHub with `git` and runs its build commands, with no checksum. Pin `@<full-commit-sha>` to fix the revision; without `@ref` the default branch is used. Review the plugin first, herdr does not sandbox plugin code.

Architectures: amd64, arm64. Debian and Ubuntu based images only (needs `apt-get`). See the [repository README](../../README.md) for the supply-chain policy.
