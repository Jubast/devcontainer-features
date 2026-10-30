#!/bin/bash
set -e

source dev-container-features-test-lib

fails() { ! "$@"; }

d="$(mktemp -d)"
cd "$d"

check "conftest on PATH" command -v conftest
check "conftest runs" conftest --version

mkdir policy
cat > policy/policy.rego <<'EOF'
package main

import rego.v1

deny contains msg if {
	input.bad
	msg := "bad is set"
}
EOF
echo '{"bad": false}' > ok.json
echo '{"bad": true}' > no.json
check "conftest passes a compliant input" conftest test --policy policy ok.json
check "conftest rejects a violating input" fails conftest test --policy policy no.json

reportResults
