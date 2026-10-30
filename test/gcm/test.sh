#!/bin/bash
set -e

source dev-container-features-test-lib

check "git-credential-manager on PATH" command -v git-credential-manager
check "git-credential-manager runs" git-credential-manager --version

reportResults
