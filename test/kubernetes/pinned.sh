#!/bin/bash
set -e

source dev-container-features-test-lib

check "kubectl pinned to 1.31.0" bash -c "kubectl version --client 2>&1 | grep -F 'v1.31.0'"
check "helm pinned to 3.16.2" bash -c "helm version --short | grep -F 'v3.16.2'"
check "kustomize pinned to 5.4.3" bash -c "kustomize version | grep -F 'v5.4.3'"
check "oc pinned to 4.16.20" bash -c "oc version --client 2>&1 | grep -F 'Client Version: 4.16.20'"
check "kubeconform pinned to 0.6.7" bash -c "kubeconform -v 2>&1 | grep -F 'v0.6.7'"

reportResults
