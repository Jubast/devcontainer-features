#!/bin/bash
set -e

source dev-container-features-test-lib

fails() { ! "$@"; }

d="$(mktemp -d)"
cd "$d"

for tool in kubectl helm kustomize oc kubeconform pluto conftest; do
    check "$tool on PATH" command -v "$tool"
done
check "helm runs" helm version --short
check "kustomize runs" kustomize version
check "oc runs" oc version --client
check "pluto runs" pluto version
check "conftest runs" conftest --version

# A minimal local schema keeps the kubeconform test offline.
mkdir schemas
cat > schemas/configmap-v1.json <<'EOS'
{
  "type": "object",
  "properties": {
    "apiVersion": { "type": "string" },
    "kind": { "type": "string" },
    "metadata": { "type": "object" },
    "data": { "type": ["object", "null"], "additionalProperties": { "type": "string" } }
  },
  "required": ["kind", "apiVersion"]
}
EOS
printf 'apiVersion: v1\nkind: ConfigMap\nmetadata:\n  name: x\ndata:\n  a: b\n' > ok.yaml
printf 'apiVersion: v1\nkind: ConfigMap\nmetadata:\n  name: x\ndata: notamap\n' > bad.yaml
SCHEMAS="$d/schemas/{{ .ResourceKind }}{{ .KindSuffix }}.json"
check "kubeconform accepts a valid manifest" kubeconform -strict -schema-location "$SCHEMAS" ok.yaml
check "kubeconform rejects an invalid manifest" fails kubeconform -strict -schema-location "$SCHEMAS" bad.yaml

reportResults
