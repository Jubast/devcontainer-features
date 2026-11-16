#!/bin/bash
set -e

source dev-container-features-test-lib

check "herdr-core pinned to 0.1.20" bash -c "herdr-core --version | grep -F '0.1.20'"

reportResults
