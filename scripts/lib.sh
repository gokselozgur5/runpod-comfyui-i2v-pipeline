#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ -f "$repo_root/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$repo_root/.env"
  set +a
fi

require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

require_var() {
  [[ -n "${!1:-}" ]] || {
    echo "Missing required setting: $1" >&2
    exit 1
  }
}

pod_ssh() {
  require_var POD_SSH_HOST
  require_var POD_SSH_PORT
  require_var POD_SSH_KEY
  ssh -i "$POD_SSH_KEY" -p "$POD_SSH_PORT" \
    -o BatchMode=yes -o StrictHostKeyChecking=accept-new \
    "root@$POD_SSH_HOST" "$@"
}

pod_scp_to() {
  scp -i "$POD_SSH_KEY" -P "$POD_SSH_PORT" \
    -o BatchMode=yes -o StrictHostKeyChecking=accept-new \
    "$1" "root@$POD_SSH_HOST:$2"
}

pod_scp_from() {
  scp -i "$POD_SSH_KEY" -P "$POD_SSH_PORT" \
    -o BatchMode=yes -o StrictHostKeyChecking=accept-new \
    "root@$POD_SSH_HOST:$1" "$2"
}
