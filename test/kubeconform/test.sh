#!/bin/bash
set -e

source dev-container-features-test-lib

fails() { ! "$@"; }

d="$(mktemp -d)"
cd "$d"

check "kubeconform on PATH" command -v kubeconform
check "kubeconform runs" kubeconform -v

printf 'apiVersion: v1\nkind: ConfigMap\nmetadata:\n  name: x\ndata:\n  a: b\n' > ok.yaml
printf 'apiVersion: v1\nkind: ConfigMap\nmetadata:\n  name: x\ndata: notamap\n' > bad.yaml
check "kubeconform accepts a valid manifest" kubeconform -strict ok.yaml
check "kubeconform rejects an invalid manifest" fails kubeconform -strict bad.yaml

reportResults
