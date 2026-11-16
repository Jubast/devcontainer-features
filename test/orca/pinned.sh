#!/bin/bash
set -e

source dev-container-features-test-lib

check "orca pinned to 1.4.259" bash -c "orca-ide --version | grep -F '1.4.259'"

reportResults
