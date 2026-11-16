#!/bin/bash
set -e

source dev-container-features-test-lib

check "herdr-core on PATH" command -v herdr-core
check "hc on PATH" command -v hc
check "hc runs" hc --version
# A client (such as the herdr app over ssh) starts the core on demand.
check "core answers over hc connect" bash -c "export HC_SESSION=featuretest; echo '{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"hello\",\"params\":{}}' | timeout 20 hc connect | grep -F '\"jsonrpc\"'; hc server stop"

reportResults
