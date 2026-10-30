#!/bin/bash
set -e

source dev-container-features-test-lib

check "yq on PATH" command -v yq
check "yq runs" yq --version

reportResults
