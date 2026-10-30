#!/bin/bash
set -e

source dev-container-features-test-lib

check "pluto pinned to 5.20.0" bash -c "pluto version 2>&1 | grep -F 'Version:5.20.0'"

reportResults
