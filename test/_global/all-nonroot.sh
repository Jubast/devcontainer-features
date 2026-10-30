#!/bin/bash
set -e

source dev-container-features-test-lib

is_not_root() { [ "$(id -u)" -ne 0 ]; }
config_dir_is_users() { [ ! -e "$HOME/.config" ] || [ "$(stat -c %u "$HOME/.config")" = "$(id -u)" ]; }
home_has_no_root_files() { [ -z "$(find "$HOME/.config" "$HOME/.local" -user root 2>/dev/null)" ]; }

check "runs as a non-root user" is_not_root
check "herdr on PATH" command -v herdr
check "git-credential-manager on PATH" command -v git-credential-manager
check "glab on PATH" command -v glab
check "oc on PATH" command -v oc
check "kubeconform on PATH" command -v kubeconform
check "pluto on PATH" command -v pluto
check "yq on PATH" command -v yq
check "conftest on PATH" command -v conftest
check "shellcheck on PATH" command -v shellcheck
check "yamllint on PATH" command -v yamllint
check "the config directory is not root-owned" config_dir_is_users
check "nothing root-owned under ~/.config or ~/.local" home_has_no_root_files

reportResults
