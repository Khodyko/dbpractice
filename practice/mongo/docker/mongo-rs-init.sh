#!/usr/bin/env bash
# Инициализация replica set rs0. Запускать из корня репозитория после compose up.
# Узлы слушают localhost:5571–5573 (host network) — приложение на хосте резолвит все members.
set -euo pipefail

COMPOSE_FILE="${COMPOSE_FILE:-practice/mongo/docker/mongo-rs.compose.yml}"
ENV_FILE="${ENV_FILE:-practice/mongo/docker/.env.example}"

MONGO_RS_PORT_1="${MONGO_RS_PORT_1:-5571}"
MONGO_RS_PORT_2="${MONGO_RS_PORT_2:-5572}"
MONGO_RS_PORT_3="${MONGO_RS_PORT_3:-5573}"

echo "Waiting for mongo1 on port ${MONGO_RS_PORT_1}..."
for _ in $(seq 1 30); do
  if docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" exec -T mongo1 \
      mongosh --port "$MONGO_RS_PORT_1" --quiet --eval "db.adminCommand('ping').ok" 2>/dev/null | grep -q 1; then
    break
  fi
  sleep 2
done

echo "Initiating replica set rs0 (idempotent)..."
docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" exec -T mongo1 mongosh --port "$MONGO_RS_PORT_1" --quiet --eval "
try {
  const s = rs.status();
  if (s.ok === 1) {
    print('Replica set already initialized: ' + s.set);
    quit(0);
  }
} catch (e) {
  // not initiated yet
}
const cfg = {
  _id: 'rs0',
  members: [
    { _id: 0, host: 'localhost:${MONGO_RS_PORT_1}' },
    { _id: 1, host: 'localhost:${MONGO_RS_PORT_2}' },
    { _id: 2, host: 'localhost:${MONGO_RS_PORT_3}' }
  ]
};
printjson(rs.initiate(cfg));
"

echo "Waiting for PRIMARY..."
for _ in $(seq 1 60); do
  STATE=$(docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" exec -T mongo1 \
    mongosh --port "$MONGO_RS_PORT_1" --quiet --eval 'rs.isMaster().ismaster' 2>/dev/null || echo "false")
  if [ "$STATE" = "true" ]; then
    echo "Replica set ready (PRIMARY on localhost:${MONGO_RS_PORT_1})."
    docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" exec -T mongo1 \
      mongosh --port "$MONGO_RS_PORT_1" --quiet --eval \
      'rs.status().members.forEach(m => print(m.name + " -> " + m.stateStr))'
    exit 0
  fi
  sleep 2
done

echo "ERROR: PRIMARY not elected in time." >&2
exit 1
