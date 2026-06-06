# MongoDB — практика доклада

Replica set (репликация, **не** sharding) + Spring Boot demo (write/read concern).

- `docker/` — [`mongo-rs.compose.yml`](docker/mongo-rs.compose.yml) (3× `mongod`), [`mongo-rs-init.sh`](docker/mongo-rs-init.sh) (`rs.initiate`)
- `demo-mongo/` — минимальное Spring Boot приложение, runbook в [`demo-mongo/README.md`](demo-mongo/README.md)

REST: `POST /orders`, `GET /orders/{id}`, `GET /orders?tenantId=`, `GET /orders/by-status?status=`

Общий runbook — в [корневом README.md](../../README.md) (раздел MongoDB).
