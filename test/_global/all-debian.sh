#!/bin/bash
set -e

source dev-container-features-test-lib

check "runs on debian" grep -q "^ID=debian" /etc/os-release
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
check "git-credential-manager runs (needs git and ICU)" git-credential-manager --version

reportResults
