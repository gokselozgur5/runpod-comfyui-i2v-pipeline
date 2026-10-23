#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

echo "Initializing Pod-local ComfyUI authentication without printing credentials..."
pod_ssh "set -e; password_file='${COMFY_ROOT:-/workspace/ComfyUI}/login/PASSWORD'; if [[ ! -s \"\$password_file\" ]]; then one_time_password=\$(head -c 48 /dev/urandom | base64 | tr -d '\\n'); curl -fsS -o /dev/null -X POST --data-urlencode 'username=automation' --data-urlencode \"password=\$one_time_password\" http://127.0.0.1:8188/login; unset one_time_password; fi; token=\$(head -n 1 \"\$password_file\"); test -n \"\$token\"; code=\$(curl -sS -o /dev/null -w '%{http_code}' -H \"Authorization: Bearer \$token\" http://127.0.0.1:8188/system_stats); test \"\$code\" = 200; echo 'ComfyUI API authentication is ready.'"
