#!/usr/bin/env bash
# Обёртка над rs.initiate() из MongoDB Manual.
# Запускать из корня репозитория ПОСЛЕ: docker compose ... up -d --wait
# https://www.mongodb.com/docs/manual/reference/method/rs.initiate/
set -euo pipefail

COMPOSE_FILE=practice/mongo/docker/mongo-rs.compose.yml

# Собрать replica set: compose поднял три mongod с --replSet, но кластер ещё не сформирован.
# exec mongo1 — зайти в первый контейнер; mongosh --eval — выполнить JS и выйти.
# host: localhost:PORT — из-за network_mode: host в compose (Spring на хосте резолвит те же адреса).
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

# Короткая пауза на выборы PRIMARY (может оказаться на любом из трёх узлов).
sleep 3

# Показать роли узлов: ожидаемо один PRIMARY и два SECONDARY.
echo "rs.status():"
docker compose -f "$COMPOSE_FILE" exec -T mongo1 mongosh --port 5571 --eval \
  'rs.status().members.forEach(m => print(m.name + " -> " + m.stateStr))'
