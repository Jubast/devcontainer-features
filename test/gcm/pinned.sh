#!/bin/bash
set -e

source dev-container-features-test-lib

check "git-credential-manager pinned to 3.0.1" bash -c "git-credential-manager --version 2>&1 | grep -F '3.0.1'"

reportResults
