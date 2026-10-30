#!/bin/bash
set -e

source dev-container-features-test-lib

check "yq pinned to 4.44.3" bash -c "yq --version 2>&1 | grep -F 'v4.44.3'"

reportResults
