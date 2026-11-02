#!/bin/bash
set -e

source dev-container-features-test-lib

check "plugin listed" bash -c "herdr plugin list | grep -F 'persiyanov.reviewr'"
check "plugin binary installed" test -x "${XDG_STATE_HOME:-$HOME/.local/state}/herdr/plugins/persiyanov.reviewr/bin/herdr-reviewr"

reportResults
