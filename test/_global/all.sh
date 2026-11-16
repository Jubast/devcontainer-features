#!/bin/bash
set -e

source dev-container-features-test-lib

check "herdr on PATH" command -v herdr
check "hc on PATH" command -v hc
check "git-credential-manager on PATH" command -v git-credential-manager
check "glab on PATH" command -v glab
for tool in kubectl helm kustomize oc kubeconform pluto conftest; do
    check "$tool on PATH" command -v "$tool"
done
check "yq on PATH" command -v yq
check "claude on PATH" command -v claude
check "codex on PATH" command -v codex
check "copilot on PATH" command -v copilot
check "shellcheck on PATH" command -v shellcheck
check "yamllint on PATH" command -v yamllint
check "tools coexist" bash -c "yq --version && shellcheck --version && yamllint --version && conftest --version"

reportResults
