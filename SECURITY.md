# Security policy

## Reporting a vulnerability

Use GitHub's private vulnerability reporting: the repository's **Security** tab, then **Report a vulnerability**. If that is unavailable, open an issue asking for a private contact and leave out the details. Reports are handled on a best-effort basis.

In scope: an install script that can be made to run attacker-controlled code, skips or weakens integrity verification, or publishes a tampered artifact; a shipped checksum that does not match the upstream release.

## Supply-chain model

- Only Microsoft's official tooling and `actions/*` and `devcontainers/*` workflow actions are used, pinned to commit SHAs.
- Installers download over HTTPS only, verify a sha256 (upstream's checksum file, or one shipped in the feature) and abort on any mismatch. Nothing is piped into a shell.
- Versions are validated before they reach a URL. Releases are tagged from `main` after lint passes.
- Signatures (sigstore, GPG) are not verified, and a checksum file from the same release as its artifact does not protect against a compromised upstream release. Pin versions and the feature digest to limit exposure.

Details per feature are in the feature READMEs and the [Supply chain](README.md#supply-chain) section.

## Release gate

Pushing a `v*.*.*` tag runs `.github/workflows/release.yaml`: a `verify` job checks that the tagged commit is on `main` and runs `scripts/lint.sh`, and `publish` needs it. Limits:

- A tag workflow runs the workflow file from the tagged commit, so anyone who can push tags can tag a branch with an altered `release.yaml`. Restrict who can create `v*` tags with a tag ruleset and, optionally, require reviewers on an environment for `publish`.
- The gate runs lint, not the feature install tests. Merge only with a green `test` workflow, and require it on `main`.
- Lint's version check compares against the previous tag, so it guards pull requests and pushes, not the tag run itself.
