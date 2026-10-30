#!/bin/bash
set -e

source dev-container-features-test-lib

fails() { ! "$@"; }

d="$(mktemp -d)"
cd "$d"

check "pluto on PATH" command -v pluto
check "pluto runs" pluto version

printf 'apiVersion: v1\nkind: ConfigMap\nmetadata:\n  name: x\n' > ok.yaml
printf 'apiVersion: extensions/v1beta1\nkind: Ingress\nmetadata:\n  name: x\nspec:\n  backend:\n    serviceName: s\n    servicePort: 80\n' > old.yaml
check "pluto passes a current API" pluto detect ok.yaml
check "pluto flags a removed API" fails pluto detect old.yaml

reportResults
