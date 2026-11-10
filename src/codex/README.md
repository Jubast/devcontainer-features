# Codex CLI (`codex`)

Installs the [Codex CLI](https://developers.openai.com/codex/plugins) and configures it each time the container is created: adds marketplaces, installs plugins and merges settings.

```jsonc
"features": {
    "ghcr.io/jubast/devcontainer-features/codex:1": {
        "marketplaces": "Jubast/common-agent-marketplace@v0.2.1",
        "plugins": "conventional-changes@common-agent-marketplace",
        "settings": "{'model':'o3','history':{'persistence':'none'}}"
    }
}
```

## Options

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `version` | string | `latest` | Version to install, e.g. `0.167.0`. A leading `v` is optional. `latest` is the newest version listed in [`checksums.txt`](checksums.txt), not the newest upstream release. |
| `marketplaces` | string | empty | Comma-separated marketplaces for `codex plugin marketplace add`: `owner/repo[@ref]` or a git URL. |
| `plugins` | string | empty | Comma-separated `plugin@marketplace` for `codex plugin add`. |
| `settings` | string | empty | JSON object (quoting: see the option description) merged into `~/.codex/config.toml` (or `$CODEX_HOME`) and written as TOML. Tables merge key by key, other keys stay, arrays are replaced. Comments are kept. |

Blank entries are ignored. Malformed options fail the build.

## Behavior

- **When.** The options are stored in the image; `postCreateCommand` applies them as the remote user on every container create (including a rebuild), after the build, so a config volume on `~/.codex` is configured too. Order: settings, marketplaces, plugins.
- **Idempotent, add-only.** Settings are re-merged and marketplaces/plugins re-added each time; already present ones are skipped. Removing an entry from an option does not uninstall it (`codex plugin remove`, `codex plugin marketplace remove`).
- **Failures warn.** A missing CLI, no network, an unknown marketplace or plugin, or an unwritable config directory print a warning and leave the container usable (rerun `/usr/local/share/devcontainer-features/codex/configure.sh apply`). A config volume that already exists keeps its old owner; the feature creates `~/.codex` owned by the remote user, which a volume created later inherits.
- **Not verified.** Marketplaces and plugins are fetched with `git` and run code with your permissions, with no checksum. Pin `@<tag-or-commit>` and review what you install.

## Source and integrity

- Source: GitHub release asset `codex-<x86_64|aarch64>-unknown-linux-musl.tar.gz` (tag `rust-v<version>`).
- **No upstream checksum file.** Releases carry sigstore bundles, which are not verified here. The sha256 of each supported release is committed in [`checksums.txt`](checksums.txt) (computed from the downloaded asset and cross-checked against GitHub's recorded digest). The install fails for a version that is not listed. Add one with `scripts/update-checksums.sh codex <version>` in a reviewed PR.

Depends on the `yq` feature of this repository (settings merge). Debian and Ubuntu based images only; amd64 and arm64. See the [repository README](../../README.md).
