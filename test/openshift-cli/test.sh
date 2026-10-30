#!/bin/bash
set -e

source dev-container-features-test-lib

check "oc on PATH" command -v oc
check "oc runs" oc version --client

reportResults
