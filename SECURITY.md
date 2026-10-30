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
