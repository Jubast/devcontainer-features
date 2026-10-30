#!/bin/bash
set -e

source dev-container-features-test-lib

check "herdr pinned to 0.9.4" bash -c "herdr --version 2>&1 | grep -F '0.9.4'"

reportResults
