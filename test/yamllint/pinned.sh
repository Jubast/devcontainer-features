#!/bin/bash
set -e

source dev-container-features-test-lib

check "yamllint pinned to 1.37.1" bash -c "yamllint --version 2>&1 | grep -F 'yamllint 1.37.1'"

reportResults
