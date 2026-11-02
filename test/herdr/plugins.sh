#!/bin/bash
set -e

source dev-container-features-test-lib

check "plugin installed" bash -c "herdr plugin list | grep -F 'agent-telegram-notify'"

reportResults
