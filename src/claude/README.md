# Claude Code (`claude`)

Installs [Claude Code](https://code.claude.com/docs/en/plugins) and configures it each time the container is created: adds marketplaces, installs plugins and merges settings.

```jsonc
"features": {
    "ghcr.io/jubast/devcontainer-features/claude:1": {
        "marketplaces": "Jubast/common-agent-marketplace#v0.2.1",
        "plugins": "chief@common-agent-marketplace, conventional-changes@common-agent-marketplace",
        "settings": "{'model':'sonnet','env':{'EDITOR':'vim'}}"
    }
}
```

## Options

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `version` | string | `latest` | Version to install, e.g. `2.1.318`. `latest` is the newest release. |
| `marketplaces` | string | empty | Comma-separated marketplaces for `claude plugin marketplace add --scope user`: `owner/repo[#ref]` or a git URL. |
| `plugins` | string | empty | Comma-separated `plugin@marketplace` for `claude plugin install --scope user`. |
| `settings` | string | empty | JSON object (quoting: see the option description) merged into `~/.claude/settings.json` (or `$CLAUDE_CONFIG_DIR`). Objects merge key by key, other keys stay, arrays are replaced. |

Blank entries are ignored. Malformed options fail the build.

## Behavior

- **When.** The options are stored in the image; `postCreateCommand` applies them as the remote user on every container create (including a rebuild), after the build, so a config volume on `~/.claude` is configured too. Order: settings, marketplaces, plugins.
- **Idempotent, add-only.** Settings are re-merged and marketplaces/plugins re-added each time; already present ones are skipped. Removing an entry from an option does not uninstall it, and changing the `#ref` of a marketplace that is already added is rejected by Claude Code: remove it first (`claude plugin marketplace remove <name>`).
- **Failures warn.** A missing CLI, no network, an unknown marketplace or plugin, or an unwritable config directory print a warning and leave the container usable (rerun `/usr/local/share/devcontainer-features/claude/configure.sh apply`). A config volume that already exists keeps its old owner; the feature creates `~/.claude` owned by the remote user, which a volume created later inherits.
- **Not verified.** Marketplaces and plugins are fetched with `git` and run code with your permissions, with no checksum. Pin `#<tag-or-commit>` and review what you install.

## Source and integrity

- Source: the official release bucket (`downloads.claude.ai/claude-code-releases/<version>/<platform>/claude`, the standalone binary).
- The sha256 is read from that release's `manifest.json` and checked before install. The manifest's own signature is not verified. `latest` reads the bucket's `latest` file.
- The standalone binary can update itself; set `DISABLE_AUTOUPDATER=1` in `containerEnv` to keep the installed version.

Depends on the `yq` feature of this repository (settings merge and manifest parsing). Debian and Ubuntu based images only; amd64 and arm64. See the [repository README](../../README.md).
