#!/usr/bin/env bash
set -euo pipefail
[[ $# -eq 2 ]] || { echo "Usage: $0 ACCEPTED_PATHS.txt OUTPUT.mp4" >&2; exit 2; }

list_file="$(mktemp)"
trap 'rm -f "$list_file"' EXIT
while IFS= read -r path; do
  [[ -n "$path" ]] || continue
  escaped="${path//\'/\'\\\'\'}"
  printf "file '%s'\n" "$escaped" >> "$list_file"
done < "$1"

mkdir -p "$(dirname "$2")"
ffmpeg -hide_banner -loglevel error -y -f concat -safe 0 -i "$list_file" -c copy "$2"
ffprobe -v error -show_entries format=duration -of default=nw=1 "$2"
