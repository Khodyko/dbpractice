# Практический стенд

Все команды `docker compose` ниже выполняются **из корня репозитория** (`dbSystemDesign`), если не указано иное.

Практика разделена на две независимые папки:

| Папка | Содержимое |
|-------|------------|
| [`practice/postgres/`](practice/postgres/) | PostgreSQL / Citus: индексы, партиции, шардирование (SQL + Docker) |
| [`practice/mongo/`](practice/mongo/) | MongoDB replica set + Spring Boot demo (concern, REST) |

---

## PostgreSQL ([`practice/postgres/`](practice/postgres/))

**SQL-скрипты** выполняются вручную (DBeaver, `psql`). Порты и учётные данные — в [`postgres/docker/.env.example`](practice/postgres/docker/.env.example).

### Обзор блоков

**Индексы**

- **Docker:** [`postgres/docker/indexes.compose.yml`](practice/postgres/docker/indexes.compose.yml)
- **SQL:** [`postgres/sql/indexes/`](practice/postgres/sql/indexes/) — `idx-01` … `idx-06`

**Партиционирование**

- **Docker:** [`postgres/docker/partitions.compose.yml`](practice/postgres/docker/partitions.compose.yml)
- **SQL:** [`postgres/sql/partitioning/`](practice/postgres/sql/partitioning/) — `part-00` … `part-03`

**Шардирование (Citus / PostgreSQL)**

- **Docker:** [`postgres/docker/sharding.compose.yml`](practice/postgres/docker/sharding.compose.yml)
- **SQL:** [`postgres/sql/sharding/`](practice/postgres/sql/sharding/) — кейсы на coordinator

### Требования

- Docker Compose v2
- Клиент PostgreSQL: DBeaver, DataGrip, `psql`

### Подключение в DBeaver

User / password по умолчанию: `demo` / `demo`. SSL для локальных контейнеров — **Disable**.

| Блок | Host | Port | Database | SQL |
|------|------|------|----------|-----|
| Индексы `idx-01` … `idx-06` | `localhost` | `5541` | `index_demo` | `postgres/sql/indexes/` |
| Партиции `part-00` … `part-03` | `localhost` | `5551` | `part_demo` | `postgres/sql/partitioning/` |
| Шардирование (coordinator) | `localhost` | `5560` | `shard_demo` | `postgres/sql/sharding/` |
| Шардирование (worker 1–3) | `localhost` | `5561`–`5563` | `shard_demo` | диагностика |

### Блок индексов

```bash
docker compose -f practice/postgres/docker/indexes.compose.yml \
  --env-file practice/postgres/docker/.env.example up -d --wait
# SQL: practice/postgres/sql/indexes/idx-01 … idx-06
docker compose -f practice/postgres/docker/indexes.compose.yml \
  --env-file practice/postgres/docker/.env.example down -v
```

### Партиционирование

```bash
docker compose -f practice/postgres/docker/partitions.compose.yml \
  --env-file practice/postgres/docker/.env.example up -d --wait
# SQL: part-00 → part-03 в practice/postgres/sql/partitioning/
docker compose -f practice/postgres/docker/partitions.compose.yml \
  --env-file practice/postgres/docker/.env.example down -v
```

### Шардирование (Citus)

```bash
docker compose -f practice/postgres/docker/sharding.compose.yml \
  --env-file practice/postgres/docker/.env.example up -d --wait
# SQL: shard-00-init, затем shard-01 … shard-06; между кейсами — postgres/sql/reset/reset-all.sql
docker compose -f practice/postgres/docker/sharding.compose.yml \
  --env-file practice/postgres/docker/.env.example down -v
```

---

## MongoDB ([`practice/mongo/`](practice/mongo/))

**Replica set** (репликация, не sharding) + минимальный Spring Boot. Runbook: [`mongo/demo-mongo/README.md`](practice/mongo/demo-mongo/README.md).

- **Docker:** [`mongo/docker/mongo-rs.compose.yml`](practice/mongo/docker/mongo-rs.compose.yml) — 3× `mongod`, порты **5571–5573**
- **Приложение:** [`mongo/demo-mongo/`](practice/mongo/demo-mongo/) — профили `strict` / `loose` (write/read concern)

```bash
docker compose -f practice/mongo/docker/mongo-rs.compose.yml \
  --env-file practice/mongo/docker/.env.example up -d --wait
./practice/mongo/docker/mongo-rs-init.sh

cd practice/mongo/demo-mongo
export MONGO_RS_URI='mongodb://localhost:5571,localhost:5572,localhost:5573/demo?replicaSet=rs0'
mvn spring-boot:run -Dspring-boot.run.profiles=strict

docker compose -f practice/mongo/docker/mongo-rs.compose.yml \
  --env-file practice/mongo/docker/.env.example down -v
```

Требования: Docker, **Java 25** или Maven через Docker (см. [`demo-mongo/README.md`](demo-mongo/README.md)).

---

## Замечания

- Если `docker compose up --wait` недоступен, используйте `up -d` и дождитесь готовности БД.
- При смене портов в `.env` обновите подключения в DBeaver / URI приложения.
