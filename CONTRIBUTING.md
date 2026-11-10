# Contributing

## Checks

Prerequisites: `bash`, `shellcheck`, `jq`, and `git` with full history and tags (`git fetch --tags`; a shallow clone skips the version check with a warning). Feature tests also need docker and the [devcontainer CLI](https://github.com/devcontainers/cli).

```sh
scripts/lint.sh                                                                      # offline: syntax, shellcheck, JSON, layout, checksums, versions, fail-closed tests, workflows
devcontainer features test -f <id> -i mcr.microsoft.com/devcontainers/base:ubuntu .  # one feature: default install, pinned scenario
devcontainer features test --global-scenarios-only .                                 # all features together
```

Run `scripts/lint.sh` before every commit; CI runs it first.

## Add a feature

1. `src/<id>/devcontainer-feature.json`, `install.sh` and `README.md`. Copy the `# --- common ---` block from an existing `install.sh`; it must stay identical in all features (edit it everywhere at once).
2. Verify every download. Use the upstream checksum file when there is one; otherwise ship `src/<id>/checksums.txt` and fill it with `scripts/update-checksums.sh`. No GitHub API calls at install time, no `curl | sh`.
3. `ensure_pkgs` everything the installer uses (bare Debian images have almost nothing), and support amd64 and arm64.
4. `test/<id>/test.sh` with a functional assertion, plus scenario scripts (e.g. `pinned.sh`) and `scenarios.json`; add the id to the matrix in `.github/workflows/test.yaml` and to `test/_global`.

In the agent harness features (`claude`, `copilot`, `codex`) each `configure.sh` holds its own harness's settings above a `# --- common ---` block that must stay identical in all of them (edit it everywhere at once).

## Change a feature

Bump its `version` in `devcontainer-feature.json`; lint fails if it is unchanged or lower. README-only edits need no bump. See [Release](README.md#release).

## Commits

Conventional commits (`feat:`, `fix:`, `docs:`, ...), short subjects, branches named `feature/...`, `bugfix/...` or `hotfix/...`.

## Maintainer settings

Settings on GitHub that the code cannot enforce:

- [ ] Enable private vulnerability reporting (Settings, Code security), which [SECURITY.md](SECURITY.md) points reporters to.
- [ ] Protect `main`: require pull requests and the `test` workflow to pass.
- [ ] Add a tag ruleset for `v*` so only maintainers can create release tags (see [Release gate](SECURITY.md#release-gate)).
- [ ] Optional: put the `publish` job behind an environment with required reviewers.
