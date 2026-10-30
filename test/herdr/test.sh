#!/bin/bash
set -e

source dev-container-features-test-lib

check "herdr on PATH" command -v herdr
check "herdr runs" herdr --version

reportResults
