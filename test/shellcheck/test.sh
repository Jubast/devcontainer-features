#!/bin/bash
set -e

source dev-container-features-test-lib

fails() { ! "$@"; }

d="$(mktemp -d)"
cd "$d"

check "shellcheck on PATH" command -v shellcheck
check "shellcheck runs" shellcheck --version

cat > bad.sh <<'EOF'
#!/bin/sh
echo $1
EOF
cat > good.sh <<'EOF'
#!/bin/sh
echo "$1"
EOF
check "shellcheck accepts a clean script" shellcheck good.sh
check "shellcheck flags an unquoted variable" fails shellcheck bad.sh

reportResults
