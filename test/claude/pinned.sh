#!/bin/bash
set -e

source dev-container-features-test-lib

# Self-update would otherwise replace the pinned version.
export DISABLE_AUTOUPDATER=1
check "claude pinned to 2.1.318" bash -c "claude --version 2>&1 | grep -F '2.1.318'"

reportResults
