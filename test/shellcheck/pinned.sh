#!/bin/bash
set -e

source dev-container-features-test-lib

check "shellcheck pinned to 0.11.0" bash -c "shellcheck --version 2>&1 | grep -F 'version: 0.11.0'"

reportResults
