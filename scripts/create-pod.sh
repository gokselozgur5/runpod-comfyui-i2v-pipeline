#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

require_command runpodctl
: "${RUNPOD_TEMPLATE_ID:=ka3hvli4kf}"
: "${RUNPOD_GPU_ID:=NVIDIA A40}"
: "${RUNPOD_DATA_CENTER:=EU-SE-1}"
: "${RUNPOD_MIN_CUDA:=12.8}"
: "${RUNPOD_VOLUME_GB:=80}"
: "${RUNPOD_POD_NAME:=i2v-pipeline}"

echo "Reading live GPU availability and price..."
runpodctl gpu list --include-unavailable | jq \
  --arg gpu "$RUNPOD_GPU_ID" \
  '.[] | select(.gpuId == $gpu)'

echo "Creating one billable Secure Cloud Pod. It bills until terminated."
runpodctl pod create \
  --template-id "$RUNPOD_TEMPLATE_ID" \
  --gpu-id "$RUNPOD_GPU_ID" \
  --gpu-count 1 \
  --cloud-type SECURE \
  --data-center-ids "$RUNPOD_DATA_CENTER" \
  --min-cuda-version "$RUNPOD_MIN_CUDA" \
  --name "$RUNPOD_POD_NAME" \
  --volume-in-gb "$RUNPOD_VOLUME_GB" \
  --volume-mount-path /workspace \
  --ports '8188/http,22/tcp' \
  --wait --wait-timeout 30m
