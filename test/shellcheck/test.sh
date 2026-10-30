#!/bin/bash
set -e

source dev-container-features-test-lib

check "shellcheck on PATH" command -v shellcheck
check "shellcheck runs" shellcheck --version

reportResults
