# AGENTS.md

Guidance for AI coding agents in this repository. `CLAUDE.md` is a symlink to this file; edit `AGENTS.md`.

## Repository

Dev container features published to `ghcr.io/jubast/devcontainer-features/<id>`. Policy: consume only Microsoft's official `devcontainers/features`; everything else is implemented here. See [README.md](README.md).

- `src/<id>/`: `devcontainer-feature.json`, `install.sh`, `README.md`.
- `test/<id>/`: `test.sh`, `pinned.sh`, `scenarios.json`; `test/_global/` for combined scenarios.
- `scripts/lint.sh`: offline checks (syntax, shellcheck, JSON, layout, workflow pinning). Run before every commit.

## Rules for install.sh

- Keep the `# --- common ---` block byte-identical across features (lint enforces it); edit it in one file, copy to all.
- Verify every download's sha256 and fail on mismatch. Never `curl | sh`. If upstream publishes no checksum, ship `src/<id>/checksums.txt` (via `scripts/update-checksums.sh`) and say so in the feature README. No GitHub API calls at install time.
- Support amd64 and arm64, run as root, be idempotent, leave no apt lists behind.
- Validate `version` before using it in a URL.
- Workflows: only `actions/*` and `devcontainers/*`, pinned to a full commit SHA with a version comment; least-privilege `permissions`.

## Git

Trunk-based. Branches: `feature/`, `bugfix/`, `hotfix/` (cut from `main`). Conventional commits, short subjects, no AI attribution, no em dashes.

## Writing style

Keep code, comments, commit messages and Markdown short and concise: no narrating the process, no padding.
