#!/bin/bash
set -e

source dev-container-features-test-lib

check "conftest pinned to 0.60.0" bash -c "conftest --version 2>&1 | grep -F 'Conftest: 0.60.0'"

reportResults
