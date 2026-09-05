#!/usr/bin/env bash
# Поднять три mongod (bridge-сеть, порты опубликованы). Для macOS/Windows Docker Desktop.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/mongo-rs-bridge.compose.yml"

docker compose -f "$COMPOSE_FILE" up -d --wait
