#!/bin/bash
set -e

source dev-container-features-test-lib

check "codex pinned to 0.166.0" bash -c "codex --version 2>&1 | grep -F '0.166.0'"

reportResults
