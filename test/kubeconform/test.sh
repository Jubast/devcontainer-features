#!/bin/bash
set -e

source dev-container-features-test-lib

fails() { ! "$@"; }

d="$(mktemp -d)"
cd "$d"

check "kubeconform on PATH" command -v kubeconform
check "kubeconform runs" kubeconform -v

# A minimal local schema keeps the test offline.
mkdir schemas
cat > schemas/configmap-v1.json <<'EOF'
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
EOF
printf 'apiVersion: v1\nkind: ConfigMap\nmetadata:\n  name: x\ndata:\n  a: b\n' > ok.yaml
printf 'apiVersion: v1\nkind: ConfigMap\nmetadata:\n  name: x\ndata: notamap\n' > bad.yaml
SCHEMAS="$d/schemas/{{ .ResourceKind }}{{ .KindSuffix }}.json"
check "kubeconform accepts a valid manifest" kubeconform -strict -schema-location "$SCHEMAS" ok.yaml
check "kubeconform rejects an invalid manifest" fails kubeconform -strict -schema-location "$SCHEMAS" bad.yaml

reportResults
