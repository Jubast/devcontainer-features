#!/bin/bash
set -e

source dev-container-features-test-lib

check "kubeconform on PATH" command -v kubeconform
check "kubeconform runs" kubeconform -v

reportResults
