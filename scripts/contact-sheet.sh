#!/usr/bin/env bash
set -euo pipefail
[[ $# -eq 2 ]] || { echo "Usage: $0 INPUT.mp4 OUTPUT.jpg" >&2; exit 2; }
mkdir -p "$(dirname "$2")"
ffmpeg -hide_banner -loglevel error -y -i "$1" \
  -vf "fps=1/2,scale=320:-1,tile=5x1" -frames:v 1 "$2"
echo "$2"
