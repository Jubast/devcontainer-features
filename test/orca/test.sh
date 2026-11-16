#!/bin/bash
set -e

source dev-container-features-test-lib

check "orca-ide on PATH" command -v orca-ide
check "orca-ide runs" orca-ide --version

reportResults
