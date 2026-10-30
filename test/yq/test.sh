#!/bin/bash
set -e

source dev-container-features-test-lib

d="$(mktemp -d)"
cd "$d"

check "yq on PATH" command -v yq
check "yq runs" yq --version

check "yq reads a value" test "$(echo 'a: 1' | yq .a)" = 1

reportResults
