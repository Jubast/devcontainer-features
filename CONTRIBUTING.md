# Contributing

## Checks

```sh
scripts/lint.sh                                                                  # offline: syntax, shellcheck, JSON, layout, checksums, workflows
devcontainer features test -f <id> -i mcr.microsoft.com/devcontainers/base:ubuntu .  # needs docker
devcontainer features test --global-scenarios-only .
```

Run `scripts/lint.sh` before every commit; CI runs it first.

## Add a feature

1. `src/<id>/devcontainer-feature.json`, `install.sh` and `README.md`. Copy the `# --- common ---` block from an existing `install.sh`; it must stay identical in all features (edit it everywhere at once).
2. Verify every download. Use the upstream checksum file when there is one; otherwise ship `src/<id>/checksums.txt` and fill it with `scripts/update-checksums.sh`. No GitHub API calls at install time, no `curl | sh`.
3. `ensure_pkgs` everything the installer uses (bare Debian images have almost nothing), and support amd64 and arm64.
4. `test/<id>/test.sh` with a functional assertion, plus `pinned.sh` and `scenarios.json`; add the id to the matrix in `.github/workflows/test.yaml` and to `test/_global`.

## Change a feature

Bump its `version` in `devcontainer-feature.json`; lint fails otherwise. See [Release](README.md#release).

## Commits

Conventional commits (`feat:`, `fix:`, `docs:`, ...), short subjects, branches named `feature/...`, `bugfix/...` or `hotfix/...`.
