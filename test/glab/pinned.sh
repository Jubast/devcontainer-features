#!/bin/bash
set -e

source dev-container-features-test-lib

check "glab pinned to 1.60.0" bash -c "glab --version 2>&1 | grep -F '1.60.0'"

reportResults
