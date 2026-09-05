#!/usr/bin/env bash
# rs.initiate() для bridge-стенда. Запускать ПОСЛЕ mongo-rs-up-bridge.sh.
# Members — имена сервисов Docker (mongo1:5571 …), не localhost.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/mongo-rs-bridge.compose.yml"

RS_NAME=$(docker compose -f "$COMPOSE_FILE" exec -T mongo1 mongosh --port 5571 --quiet --eval \
  'try { print(rs.status().set) } catch (e) { print("") }' 2>/dev/null || true)

if [ -n "$RS_NAME" ]; then
  echo "rs0 уже инициализирован (set=$RS_NAME), rs.initiate пропускаем."
else
  echo "rs.initiate(rs0) [bridge]..."
  docker compose -f "$COMPOSE_FILE" exec -T mongo1 mongosh --port 5571 --eval '
rs.initiate({
  _id: "rs0",
  members: [
    { _id: 0, host: "mongo1:5571" },
    { _id: 1, host: "mongo2:5572" },
    { _id: 2, host: "mongo3:5573" }
  ]
})'
fi

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
