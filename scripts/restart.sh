#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if [[ ! -f mempalace-common-http.env ]]; then
  echo "Missing mempalace-common-http.env. Copy mempalace-common-http.env.example first." >&2
  exit 1
fi

docker compose up -d --build --force-recreate mempalace-http

