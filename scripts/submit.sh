#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

for command in jq ssh scp; do require_command "$command"; done
[[ $# -eq 2 ]] || { echo "Usage: $0 SOURCE_IMAGE WORKFLOW_JSON" >&2; exit 2; }

image="$1"
workflow="$2"
[[ -f "$image" && -f "$workflow" ]] || { echo "Input file missing." >&2; exit 1; }

remote_image="$(basename "$image")"
remote_workflow="/workspace/i2v-workflow.json"
remote_payload="/workspace/i2v-payload.json"

pod_scp_to "$image" "${COMFY_ROOT:-/workspace/ComfyUI}/input/$remote_image"

tmp_payload="$(mktemp)"
trap 'rm -f "$tmp_payload"' EXIT
jq --arg image "$remote_image" '."395".inputs.image = $image | {prompt:.}' "$workflow" > "$tmp_payload"
pod_scp_to "$tmp_payload" "$remote_payload"
pod_scp_to "$workflow" "$remote_workflow"

pod_ssh "set -e; token=\$(head -n 1 '${COMFY_ROOT:-/workspace/ComfyUI}/login/PASSWORD'); test -n \"\$token\"; curl -fsS -H \"Authorization: Bearer \$token\" -H 'Content-Type: application/json' --data-binary '@$remote_payload' http://127.0.0.1:8188/prompt | jq -r .prompt_id"
