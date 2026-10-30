#!/bin/bash
set -e

source dev-container-features-test-lib

check "glab on PATH" command -v glab
check "glab runs" glab --version

reportResults
