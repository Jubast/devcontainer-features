#!/bin/bash
set -e

source dev-container-features-test-lib

check "pluto on PATH" command -v pluto
check "pluto runs" pluto version

reportResults
