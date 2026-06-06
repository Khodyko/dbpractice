#!/usr/bin/env bash
# Обёртка над rs.initiate() из MongoDB Manual.
# Запускать ПОСЛЕ mongo-rs-up.sh
# https://www.mongodb.com/docs/manual/reference/method/rs.initiate/
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/mongo-rs.compose.yml"

# Собрать replica set: compose поднял три mongod с --replSet, но кластер ещё не сформирован.
# exec mongo1 — зайти в первый контейнер; mongosh --eval — выполнить JS и выйти.
# host: localhost:PORT — из-за network_mode: host в compose.
echo "rs.initiate(rs0)..."
docker compose -f "$COMPOSE_FILE" exec -T mongo1 mongosh --port 5571 --eval '
rs.initiate({
  _id: "rs0",
  members: [
    { _id: 0, host: "localhost:5571" },
    { _id: 1, host: "localhost:5572" },
    { _id: 2, host: "localhost:5573" }
  ]
})'

echo "Waiting for PRIMARY..."
for _ in $(seq 1 15); do
  HAS_PRIMARY=$(docker compose -f "$COMPOSE_FILE" exec -T mongo1 mongosh --port 5571 --quiet --eval \
    'print(rs.status().members.some(m => m.stateStr === "PRIMARY") ? "yes" : "")' 2>/dev/null || true)
  if [ "$HAS_PRIMARY" = "yes" ]; then
    break
  fi
  sleep 2
done

echo "rs.status():"
docker compose -f "$COMPOSE_FILE" exec -T mongo1 mongosh --port 5571 --eval \
  'rs.status().members.forEach(m => print(m.name + " -> " + m.stateStr))'
