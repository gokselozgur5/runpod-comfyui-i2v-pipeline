# Pipeline design

## Control plane and data plane

`runpodctl` manages the Pod lifecycle. SSH carries input files and API payloads. ComfyUI runs only on the Pod and receives workflow submissions through its localhost API. This separation avoids putting ComfyUI credentials in local workflow files or exposing the API directly to the internet.

## Lifecycle

```text
read stock and price
        |
        v
create disposable Pod
        |
        v
wait for SSH -> wait for ComfyUI -> wait for model downloads
        |
        v
initialize Pod-local API authentication
        |
        v
upload source -> submit one proof clip -> inspect
        |
        v
submit independent clips -> download -> review -> concatenate
        |
        v
terminate Pod -> verify empty inventories and zero hourly spend
```

Service readiness and model readiness are different states. An HTTP 200 from ComfyUI does not prove that every model referenced by a workflow exists. The scripts therefore wait until background model downloads finish before submission.

## Workflow mutation

The included workflow is an API-format ComfyUI graph. For a batch, copy it once per scene and change only:

- `LoadImage.inputs.image`;
- the positive prompt;
- the negative prompt when necessary;
- both noise seeds;
- the output filename prefix.

Keep duration, resolution, model filenames, and sampler settings constant until one proof clip succeeds. This makes failures easier to attribute.

## Review strategy

Generate a contact sheet for quick triage, then watch every accepted clip at normal speed and frame-step suspicious moments. Diffusion failures often last only a few frames and disappear from a sparse contact sheet.

## Failure handling

- SSH ready but ComfyUI unavailable: inspect container logs; do not create another Pod.
- ComfyUI ready but workflow rejects a model: provisioning is incomplete or filenames differ from the graph.
- A prompt stays in the running queue: inspect GPU memory and ComfyUI logs before retrying.
- One malformed clip: discard it and rerun only that scene with a new seed or simpler motion.
- Cleanup command fails: list Pods and volumes immediately and terminate the exact resource created by the session.
