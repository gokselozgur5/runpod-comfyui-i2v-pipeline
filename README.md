# Runpod ComfyUI Image-to-Video Pipeline

A small, auditable workflow for turning one source image into several short image-to-video clips on a disposable Runpod GPU Pod, reviewing the results, and assembling the accepted clips locally.

The repository focuses on infrastructure and automation. It contains no product-specific characters, private assets, credentials, or generated media.

## What it demonstrates

1. Create a temporary Runpod Pod from a public ComfyUI template.
2. Wait for SSH, ComfyUI, and model provisioning separately.
3. Upload an input image and API-format ComfyUI workflow.
4. Submit one clip first and inspect it before spending on a batch.
5. Generate independent clips with explicit prompts and seeds.
6. Download outputs, build contact sheets, and concatenate accepted clips.
7. Terminate the Pod and verify that hourly spend returns to zero.

## Requirements

- macOS or Linux
- `runpodctl` 3.x
- `ssh`, `scp`, `curl`, `jq`, and `ffmpeg`
- A Runpod API key configured locally
- A Runpod account with enough balance for the selected GPU

Never commit an API key. Configure it with `runpodctl doctor` or export it only in your shell.

## Quick start

Copy the example environment file and edit the non-secret settings:

```bash
cp .env.example .env
$EDITOR .env
```

Create a disposable Pod:

```bash
scripts/create-pod.sh
```

The command prints a Pod ID and SSH connection information. Add the assigned values to `.env`, then wait for the service and models:

```bash
scripts/wait-ready.sh
scripts/setup-comfy-auth.sh
```

Upload a source image and submit the example workflow:

```bash
scripts/submit.sh path/to/source.png workflows/i2v-10s.example.json
```

After the job completes, download its output:

```bash
scripts/download-output.sh PROMPT_ID outputs/clip-01.mp4
```

Review several clips and assemble only the accepted files:

```bash
scripts/contact-sheet.sh outputs/clip-01.mp4 review/clip-01.jpg
printf '%s\n' outputs/clip-01.mp4 outputs/clip-02.mp4 > accepted.txt
scripts/concat.sh accepted.txt outputs/final.mp4
```

Terminate the temporary Pod when finished:

```bash
scripts/cleanup.sh
```

## Why independent clips?

Long diffusion videos tend to accumulate identity drift, malformed hands, changing objects, and temporal artifacts. Independent 5–10 second clips make failures cheap to discard and allow each motion to have its own seed and prompt. The final duration comes from editing accepted clips, not asking the model to sustain one minute of perfect continuity.

## Quality gates

Check every clip for:

- face and identity continuity;
- eye direction and blinking;
- teeth, fingers, and hands;
- clothing and background drift;
- object shape changes;
- unwanted cuts, zooms, or camera motion;
- duration, frame rate, resolution, and codec.

Contact sheets are useful for coarse screening. Watch the full clip before accepting it; a five-frame sheet can miss a one-frame defect.

## Cost controls

- Read live GPU price and stock immediately before creation.
- Generate one proof clip before submitting a batch.
- Keep only one Pod for the batch so models download once.
- Do not trust client-side `stop-after` timers as a cleanup mechanism.
- Terminate throwaway Pods and verify both Pod and network-volume inventories afterward.
- Re-read account hourly spend after cleanup.

The default example uses the public LTX 2.5 ComfyUI template and an NVIDIA A40. Prices and availability change; the scripts read live state instead of documenting a fixed price.

## Security

- `.env`, source images, generated media, cookies, API payload responses, and SSH host material are ignored by Git.
- API calls execute through SSH against Pod-local ComfyUI by default.
- The example never prints the ComfyUI password or hashed API token.
- Treat public Runpod proxy URLs as unauthenticated unless the deployed image provides its own access control.

## Repository layout

```text
scripts/       Pod lifecycle, submission, download, review, and assembly
workflows/     Generic ComfyUI API workflow examples
docs/          Pipeline design and troubleshooting notes
```

## License

MIT
