# oc (`openshift-cli`)

Installs the OpenShift CLI (`oc`) from `mirror.openshift.com`.

```jsonc
"features": {
    "ghcr.io/jubast/devcontainer-features/openshift-cli:1": {}
}
```

## Options

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `version` | string | `latest` | Version to install, e.g. `stable-4.16`. Mirror directory, see below. |

## Source and integrity

- Source: `openshift-client-linux[-arm64].tar.gz` in the mirror directory for the version.
- Verified against the `sha256sum.txt` in the same mirror directory. The mirror's GPG signature is not checked.

## Notes

`version` is a mirror directory: `stable`, `stable-4.16`, `4.16.20`, ... `latest` means `stable`. Only `oc` is installed (not `kubectl`; use the official kubectl feature).

Architectures: amd64, arm64. See the [repository README](../../README.md) for the supply-chain policy.
