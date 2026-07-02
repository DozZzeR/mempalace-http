# MemPalace HTTP Deploy

Small deployment wrapper for running MemPalace as a local HTTP MCP service.

MemPalace itself is a stdio-first MCP server. That is the right default for
desktop MCP clients, but it is awkward for bots, workers, and other local
services that need to submit a job and come back later. This wrapper packages
the same MemPalace image with HTTP transport enabled, a bearer-token boundary,
and a repeatable local deployment shape.

## What This Gives You

- A local HTTP MCP endpoint at `127.0.0.1:4118/mcp`.
- Bearer-token authentication through `MEMPALACE_HTTP_BEARER_TOKEN`.
- A stable Docker container name: `mem-palace-common-http`.
- A persistent Docker volume: `mempalace-common-data`.
- Optional Caddy reverse-proxy examples for controlled external access.
- A clean place for operational scripts without mixing host secrets into the
  MemPalace core repository.

## Why This Exists

This repo is the deployment layer, not the MemPalace product code.

The wrapper has value on its own because agents and bots often need HTTP:

1. Upload API docs or other files through MCP.
2. Start a long-running mine with `background: true`.
3. Store the returned `job_id`.
4. Poll `mempalace_api_ingest_job_status` until the job is done.

That flow avoids keeping a bot blocked on a long synchronous HTTP request.

## Repository Split

- MemPalace source: `git@github.com:DozZzeR/mempalace.git`
- This wrapper: `git@github.com:DozZzeR/mempalace-http.git`

The wrapper expects a local base image named `mempalace:local`. Build that from
the MemPalace source repository first, then build this HTTP image on top.

## Files

- `Dockerfile.http` - thin image layer over `mempalace:local` that enables HTTP transport.
- `docker-compose.yml` - local service definition for the HTTP MCP server.
- `mempalace-common-http.env.example` - safe example env file.
- `Caddyfile.mempalace.example` - reverse proxy example with bearer-token gate.
- `scripts/rebuild.sh` - build the HTTP wrapper image.
- `scripts/restart.sh` - recreate the service container.
- `scripts/smoke-test.sh` - verify health and MCP tool availability.

## Setup

Build the base MemPalace image from the MemPalace source checkout:

```bash
cd /path/to/mempalace
docker build -t mempalace:local .
```

Create a real env file from the example:

```bash
cp mempalace-common-http.env.example mempalace-common-http.env
chmod 600 mempalace-common-http.env
```

Generate a token and put it into `mempalace-common-http.env`:

```bash
openssl rand -hex 32
```

Build and start the HTTP wrapper:

```bash
./scripts/rebuild.sh
./scripts/restart.sh
```

Verify it:

```bash
./scripts/smoke-test.sh
```

## Endpoint

Default local endpoint:

```text
http://127.0.0.1:4118/mcp
```

Health endpoint:

```text
http://127.0.0.1:4118/healthz
```

## Secret Handling

Do not commit the real env file.

The real token lives in:

```text
mempalace-common-http.env
```

Only the example file is tracked:

```text
mempalace-common-http.env.example
```

Docker still receives the token as an environment variable inside the container.
That is acceptable for this local deployment model, but anyone with Docker
admin access on the host can inspect it. Keep the service bound to localhost
unless you intentionally place it behind a reverse proxy with authentication.

## Async API Ingest Flow

For large API docs, call:

```json
{
  "name": "mempalace_api_ingest_process",
  "arguments": {
    "batch_id": "your_batch",
    "wing": "api_some_provider",
    "background": true
  }
}
```

The response contains a `job_id`. Poll:

```json
{
  "name": "mempalace_api_ingest_job_status",
  "arguments": {
    "job_id": "api_ingest_..."
  }
}
```

Statuses are `queued`, `running`, `succeeded`, or `failed`.

Job status is currently in-memory for the running MemPalace HTTP process. If the
container restarts, job history is lost, but already-filed palace data remains
in the persistent volume.

