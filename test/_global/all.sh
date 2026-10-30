#!/bin/bash
set -e

source dev-container-features-test-lib

check "herdr" command -v herdr
check "git-credential-manager" command -v git-credential-manager
check "glab" command -v glab
check "oc" command -v oc
check "kubeconform" command -v kubeconform
check "pluto" command -v pluto
check "yq" command -v yq
check "conftest" command -v conftest
check "shellcheck" command -v shellcheck
check "yamllint" command -v yamllint

reportResults
