#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

for command in jq ssh scp; do require_command "$command"; done
[[ $# -eq 2 ]] || { echo "Usage: $0 PROMPT_ID LOCAL_OUTPUT.mp4" >&2; exit 2; }

prompt_id="$1"
destination="$2"
remote_history="/workspace/history-$prompt_id.json"

for attempt in $(seq 1 80); do
  status="$(pod_ssh "token=\$(head -n 1 '${COMFY_ROOT:-/workspace/ComfyUI}/login/PASSWORD'); curl -fsS -H \"Authorization: Bearer \$token\" 'http://127.0.0.1:8188/history/$prompt_id' > '$remote_history'; jq -r --arg id '$prompt_id' '.[\$id].status.completed // false' '$remote_history'")"
  [[ "$status" == "true" ]] && break
  printf 'attempt=%s completed=%s\n' "$attempt" "$status"
  sleep 15
done

remote_file="$(pod_ssh "jq -er --arg id '$prompt_id' '.[\$id].outputs[] | ((.video // []) + (.images // []))[]? | select(.filename | endswith(\".mp4\")) | ((if (.subfolder // \"\") == \"\" then \"\" else .subfolder + \"/\" end) + .filename)' '$remote_history' | head -n 1")"
[[ -n "$remote_file" ]] || { echo "No video output found for $prompt_id" >&2; exit 1; }
mkdir -p "$(dirname "$destination")"
pod_scp_from "${COMFY_ROOT:-/workspace/ComfyUI}/output/$remote_file" "$destination"
ffprobe -v error -show_entries stream=codec_name,width,height,r_frame_rate -show_entries format=duration -of json "$destination"
