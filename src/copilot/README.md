# GitHub Copilot CLI (`copilot`)

Installs the [GitHub Copilot CLI](https://docs.github.com/copilot/concepts/agents/copilot-cli/about-cli-plugins) and configures it each time the container is created: adds marketplaces, installs plugins and merges settings.

```jsonc
"features": {
    "ghcr.io/jubast/devcontainer-features/copilot:1": {
        "marketplaces": "Jubast/common-agent-marketplace#v0.2.1",
        "plugins": "conventional-changes@common-agent-marketplace",
        "settings": "{'model':'claude-sonnet-5.5','footer':{'showQuota':false}}"
    }
}
```

## Options

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `version` | string | `latest` | Version to install, e.g. `1.0.108`. A leading `v` is optional. `latest` is the newest release. |
| `marketplaces` | string | empty | Comma-separated marketplaces for `copilot plugin marketplace add`: `owner/repo[#ref]` or a git URL. |
| `plugins` | string | empty | Comma-separated `plugin@marketplace` (or `owner/repo`) for `copilot plugin install`. |
| `settings` | string | empty | JSON object (quoting: see the option description) merged into `~/.copilot/settings.json` (or `$COPILOT_HOME`). Objects merge key by key, other keys stay, arrays are replaced. |

Blank entries are ignored. Malformed options fail the build.

## Behavior

- **When.** The options are stored in the image; `postCreateCommand` applies them as the remote user on every container create (including a rebuild), after the build, so a config volume on `~/.copilot` is configured too. Order: settings, marketplaces, plugins.
- **Idempotent, add-only.** Settings are re-merged and marketplaces/plugins re-added each time; already present ones are skipped. Removing an entry from an option does not uninstall it, and a marketplace that is already added keeps its ref (`copilot plugin marketplace remove <name>` first).
- **Failures warn.** A missing CLI, no network, an unknown marketplace or plugin, or an unwritable config directory print a warning and leave the container usable (rerun `/usr/local/share/devcontainer-features/copilot/configure.sh apply`). A config volume that already exists keeps its old owner; the feature creates `~/.copilot` owned by the remote user, which a volume created later inherits.
- **Not verified.** Marketplaces and plugins are fetched with `git` and run code with your permissions, with no checksum. Pin `#<tag-or-commit>` and review what you install.

## Source and integrity

- Source: GitHub release asset `copilot-linux-<x64|arm64>.tar.gz`.
- Verified against the release's `SHA256SUMS.txt`.
- The CLI can update itself; set `COPILOT_AUTO_UPDATE=false` in `containerEnv` to keep the installed version.

Depends on the `yq` feature of this repository (settings merge). Debian and Ubuntu based images only; amd64 and arm64. See the [repository README](../../README.md).
