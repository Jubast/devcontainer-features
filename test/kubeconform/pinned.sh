#!/bin/bash
set -e

source dev-container-features-test-lib

check "kubeconform pinned to 0.6.7" bash -c "kubeconform -v 2>&1 | grep -F 'v0.6.7'"

reportResults
