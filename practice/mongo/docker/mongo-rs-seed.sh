#!/usr/bin/env bash
# Наполнить demo.orders учебными документами для показа explain.
# Не трогает shell@ / rest@ / smoke@ — только email с префиксом seed-.
# Повторный запуск: старые seed-* удаляет и заливает заново.
#
# Использование (из корня репозитория или откуда угодно):
#   practice/mongo/docker/mongo-rs-seed.sh        # 5000 документов
#   practice/mongo/docker/mongo-rs-seed.sh 3000   # своё число
#
# Нужны поднятый RS (mongo-rs-up + init). demo-mongo не обязателен.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/mongo-rs.compose.yml"
SEED_JS="${SCRIPT_DIR}/mongo-rs-seed-orders.js"
COUNT="${1:-5000}"
REMOTE_JS="/tmp/mongo-rs-seed-orders.js"

if ! [[ "$COUNT" =~ ^[1-9][0-9]*$ ]]; then
  echo "COUNT должен быть положительным целым, получено: $COUNT" >&2
  exit 1
fi

if [ "$COUNT" -gt 100000 ]; then
  echo "Слишком большое COUNT ($COUNT). Для локального показа обычно хватает 2000–10000." >&2
  exit 1
fi

CID="$(docker compose -f "$COMPOSE_FILE" ps -q mongo1)"
if [ -z "$CID" ]; then
  echo "Контейнер mongo1 не запущен. Сначала: practice/mongo/docker/mongo-rs-up.sh && mongo-rs-init.sh" >&2
  exit 1
fi

echo "Seed demo.orders: ${COUNT} документов (email seed-*@demo.local)..."

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT
{
  echo "const SEED_COUNT = ${COUNT};"
  cat "$SEED_JS"
} > "$TMP"

docker cp "$TMP" "${CID}:${REMOTE_JS}"
docker compose -f "$COMPOSE_FILE" exec -T mongo1 mongosh --port 5571 --quiet "$REMOTE_JS"

echo "OK"
