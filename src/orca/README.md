# Orca (`orca`)

Installs the [Orca](https://github.com/stablyai/orca) (onorca.dev) server-only build as `orca-ide`. It bundles its own Node and needs no display, GPU or desktop libraries.

```jsonc
"features": {
    "ghcr.io/jubast/devcontainer-features/orca:1": {}
}
```

## Options

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `version` | string | `latest` | Version to install, e.g. `1.4.261`. A leading `v` is optional. Only releases that ship a server build are supported (1.4.256 and later); earlier ones fail the install. |

## Use

The server is extracted to `/opt/orca` and `orca-ide` in `/usr/local/bin` links to it. Nothing runs after the install. Start the server with:

```sh
orca-ide serve --port 6768 --pairing-address <address>
```

The server grants whoever can reach its port full access to the container: bind it to localhost or a private network only.

Update by changing `version` and rebuilding the container.

## Source and integrity

- Source: `https://github.com/stablyai/orca/releases/download/v<version>/orca-server-linux-<x64|arm64>.tar.gz`.
- Integrity: the install checks the tarball's sha256 against the release's `orca-server-sha256sums.txt` and aborts on a mismatch or a missing entry.

Architectures: amd64, arm64. Debian and Ubuntu based images only (needs `apt-get`). See the [repository README](../../README.md) for the supply-chain policy.
