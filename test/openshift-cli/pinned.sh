#!/bin/bash
set -e

source dev-container-features-test-lib

check "oc pinned to 4.16.20" bash -c "oc version --client 2>&1 | grep -F 'Client Version: 4.16.20'"

reportResults
