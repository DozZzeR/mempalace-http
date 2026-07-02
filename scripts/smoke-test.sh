#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if [[ ! -f mempalace-common-http.env ]]; then
  echo "Missing mempalace-common-http.env. Copy mempalace-common-http.env.example first." >&2
  exit 1
fi

TOKEN="$(grep '^MEMPALACE_HTTP_BEARER_TOKEN=' mempalace-common-http.env | cut -d= -f2-)"

curl -fsS http://127.0.0.1:4118/healthz
echo

curl -fsS \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${TOKEN}" \
  --data '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' \
  http://127.0.0.1:4118/mcp \
  | python3 -c 'import json,sys; data=json.load(sys.stdin); tools=[t["name"] for t in data["result"]["tools"]]; print(f"tools={len(tools)}"); print("mempalace_api_ingest_job_status" in tools)'

