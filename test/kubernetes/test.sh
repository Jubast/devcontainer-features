#!/bin/bash
set -e

source dev-container-features-test-lib

check "kubectl on PATH" command -v kubectl
check "kubectl runs" kubectl version --client
check "no extension by default" bash -c "! command -v helm && ! command -v oc"

reportResults
