#!/bin/bash
set -e

source dev-container-features-test-lib

check "conftest on PATH" command -v conftest
check "conftest runs" conftest --version

reportResults
