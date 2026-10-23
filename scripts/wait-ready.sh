#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

for command in ssh curl; do require_command "$command"; done

echo "Waiting for ComfyUI and model provisioning..."
for attempt in $(seq 1 120); do
  state="$(pod_ssh 'if pgrep -f "hf download" >/dev/null; then echo downloading; elif curl -sS -o /dev/null http://127.0.0.1:8188/login; then echo ready; else echo starting; fi')"
  printf 'attempt=%s state=%s\n' "$attempt" "$state"
  [[ "$state" == "ready" ]] && exit 0
  sleep 15
done

echo "Timed out while waiting for provisioning." >&2
exit 124
