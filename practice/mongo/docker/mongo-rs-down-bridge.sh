#!/usr/bin/env bash
# Остановить bridge replica set и удалить volumes.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/mongo-rs-bridge.compose.yml"

docker compose -f "$COMPOSE_FILE" down -v
