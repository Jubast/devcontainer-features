#!/usr/bin/env bash
# Configures Claude Code: marketplaces, plugins and user settings from the feature options.
#   configure.sh install   image build, as root: validate the options and keep them for apply
#   configure.sh apply     every container create, as the remote user: apply them
set -uo pipefail

# The CLI, its config directory (default name and the env var that moves it), the user settings
# file, and how to add a marketplace and a plugin.
HARNESS=claude
CLI=claude
DIR_NAME=.claude
DIR_ENV=CLAUDE_CONFIG_DIR
SETTINGS_FILE=settings.json
MARKETPLACE_ADD=(claude plugin marketplace add)
PLUGIN_ADD=(claude plugin install)
SCOPE_ARGS=(--scope user)

# --- common (identical in every harness configure.sh, enforced by scripts/lint.sh) ---
FORMAT="${SETTINGS_FILE##*.}" # json or toml
STATE_DIR="${HARNESS_STATE_DIR:-/usr/local/share/devcontainer-features/$HARNESS}"

MARKETPLACES="${MARKETPLACES:-}"
PLUGINS="${PLUGINS:-}"
SETTINGS="${SETTINGS:-}"

warn() { echo "WARNING: $HARNESS: $*" >&2; }

# list_items LIST: print the entries of a comma-separated list, trimmed, blanks dropped.
# An entry must be one word that does not start with '-' (it is passed to the CLI as an argument).
list_items() {
    local entry entries
    IFS=',' read -ra entries <<<"$1"
    for entry in "${entries[@]}"; do
        entry="${entry#"${entry%%[![:space:]]*}"}"; entry="${entry%"${entry##*[![:space:]]}"}"
        [ -n "$entry" ] || continue
        [[ "$entry" =~ ^[A-Za-z0-9._~][A-Za-z0-9._/:@#~+=-]*$ ]] || { echo "Invalid entry '$entry'." >&2; return 1; }
        echo "$entry"
    done
}

install_options() {
    [ "$(id -u)" -eq 0 ] || { echo "Must run as root." >&2; exit 1; }
    list_items "$MARKETPLACES" >/dev/null || exit 1
    list_items "$PLUGINS" >/dev/null || exit 1
    # The container CLI strips double quotes from option values, so settings use single quotes.
    SETTINGS="${SETTINGS//\'/\"}"
    if [ -n "$SETTINGS" ] && [ "$(yq -p json tag <<<"$SETTINGS" 2>/dev/null)" != '!!map' ]; then
        echo "'settings' must be a JSON object with single quotes instead of double quotes." >&2; exit 1
    fi

    install -d "$STATE_DIR"
    install -m 0755 "${BASH_SOURCE[0]}" "$STATE_DIR/configure.sh"
    declare -p MARKETPLACES PLUGINS SETTINGS >"$STATE_DIR/options.env"

    # A named volume mounted on the config directory takes the owner of this directory when it is
    # first created, so the remote user (not root) can write to it.
    local user="${_REMOTE_USER:-root}" home
    id "$user" >/dev/null 2>&1 || user=root
    home="${_REMOTE_USER_HOME:-$(getent passwd "$user" | cut -d: -f6)}"
    install -d -o "$user" -g "$(id -gn "$user")" "$home/$DIR_NAME"
}

# attempt WHAT CMD...: a failure (network, registry, bad name) warns and does not fail the container.
# "already ..." is not a failure: some CLIs reject a marketplace that is registered.
attempt() {
    local what="$1" out
    shift
    out="$(timeout 300 "$@" 2>&1)" && return 0
    grep -qi 'already' <<<"$out" && return 0
    warn "$what failed: $out"
}

# Merge the settings into the user settings file; other keys stay, arrays are replaced.
merge_settings() {
    [ -n "$SETTINGS" ] || return 0
    local file="$CONFIG_DIR/$SETTINGS_FILE"
    echo "$HARNESS: merging settings into $file"
    { mkdir -p "$CONFIG_DIR" && touch "$file" \
        && yq -i -p "$FORMAT" -o "$FORMAT" '. *= (strenv(SETTINGS) | from_json)' "$file"; } \
        || warn "could not merge into $file"
}

apply_options() {
    # shellcheck source=/dev/null
    source "$STATE_DIR/options.env"
    CONFIG_DIR="${!DIR_ENV:-$HOME/$DIR_NAME}"
    export SETTINGS

    merge_settings

    if ! command -v "$CLI" >/dev/null 2>&1; then
        warn "$CLI is not installed, skipping marketplaces and plugins."
        return 0
    fi
    local item
    while IFS= read -r item; do
        echo "$HARNESS: marketplace $item"
        attempt "adding marketplace $item" "${MARKETPLACE_ADD[@]}" "$item" "${SCOPE_ARGS[@]}"
    done < <(list_items "$MARKETPLACES")
    while IFS= read -r item; do
        echo "$HARNESS: plugin $item"
        attempt "installing plugin $item" "${PLUGIN_ADD[@]}" "$item" "${SCOPE_ARGS[@]}"
    done < <(list_items "$PLUGINS")
}

case "${1:?mode}" in
    install) install_options ;;
    apply) apply_options ;;
    *) echo "Unknown mode: $1" >&2; exit 1 ;;
esac
# --- end common ---
