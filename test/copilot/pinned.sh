#!/bin/bash
set -e

source dev-container-features-test-lib

# Self-update would otherwise run a newer cached version.
export COPILOT_AUTO_UPDATE=false
check "copilot pinned to 1.0.100" bash -c "copilot --version 2>&1 | grep -F '1.0.100'"

reportResults
