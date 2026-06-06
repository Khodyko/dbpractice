#!/usr/bin/env bash
# Поднять три mongod. Путь к compose — относительно расположения скрипта (Run из IntelliJ OK).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/mongo-rs.compose.yml"

docker compose -f "$COMPOSE_FILE" up -d --wait
