#!/bin/bash
set -e

source dev-container-features-test-lib

check "yamllint on PATH" command -v yamllint
check "yamllint runs" yamllint --version

reportResults
