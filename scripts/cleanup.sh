#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

require_command runpodctl
require_var RUNPOD_POD_ID

echo "Terminating Pod $RUNPOD_POD_ID. Its Pod volume will be deleted."
runpodctl pod remove "$RUNPOD_POD_ID"

echo "Verifying account state..."
runpodctl pod list
runpodctl network-volume list
runpodctl user | jq '{clientBalance,currentSpendPerHr}'
