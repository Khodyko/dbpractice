# Практический стенд

Все команды `docker compose` ниже выполняются **из корня репозитория** (`dbSystemDesign`), если не указано иное.

**Домашняя работа:**

| Блок | Задание | Как выполнить |
|------|---------|---------------|
| PostgreSQL | [`practice/postgres/HOMEWORK.md`](practice/postgres/HOMEWORK.md) | [`practice/postgres/ANSWERS.md`](practice/postgres/ANSWERS.md) |
| MongoDB | [`practice/mongo/HOMEWORK.md`](practice/mongo/HOMEWORK.md) | [`practice/mongo/ANSWERS.md`](practice/mongo/ANSWERS.md) |

Практика разделена на две независимые папки:

| Папка | Содержимое |
|-------|------------|
| [`practice/postgres/`](practice/postgres/) | PostgreSQL / Citus: индексы, партиции, шардирование (SQL + Docker) |
| [`practice/mongo/`](practice/mongo/) | MongoDB replica set + Spring Boot demo (concern, REST) |

---

## PostgreSQL ([`practice/postgres/`](practice/postgres/))

**Домашняя работа:** [`practice/postgres/HOMEWORK.md`](practice/postgres/HOMEWORK.md) · [`ANSWERS.md`](practice/postgres/ANSWERS.md)

**SQL-скрипты** выполняются вручную (IntelliJ Database, DBeaver, `psql`). Порты и учётные данные — в [`postgres/docker/.env.example`](practice/postgres/docker/.env.example).

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

SQL: `practice/postgres/sql/indexes/idx-01` … `idx-06`

```bash
docker compose -f practice/postgres/docker/indexes.compose.yml \
  --env-file practice/postgres/docker/.env.example up -d --wait
```

```bash
docker compose -f practice/postgres/docker/indexes.compose.yml \
  --env-file practice/postgres/docker/.env.example down -v
```

### Партиционирование

SQL: `part-00` → `part-03` в `practice/postgres/sql/partitioning/`

```bash
docker compose -f practice/postgres/docker/partitions.compose.yml \
  --env-file practice/postgres/docker/.env.example up -d --wait
```

```bash
docker compose -f practice/postgres/docker/partitions.compose.yml \
  --env-file practice/postgres/docker/.env.example down -v
```

### Шардирование (Citus)

SQL: `shard-00-init`, затем `shard-01` … `shard-06`; между кейсами — `postgres/sql/reset/reset-all.sql`

```bash
docker compose -f practice/postgres/docker/sharding.compose.yml \
  --env-file practice/postgres/docker/.env.example up -d --wait
```

```bash
docker compose -f practice/postgres/docker/sharding.compose.yml \
  --env-file practice/postgres/docker/.env.example down -v
```

---

## MongoDB ([`practice/mongo/`](practice/mongo/))

**Домашняя работа:** [`practice/mongo/HOMEWORK.md`](practice/mongo/HOMEWORK.md) · [`ANSWERS.md`](practice/mongo/ANSWERS.md)

**Сценарий доклада:** [`mongoDemo.md`](mongoDemo.md)

Краткий запуск RS (Linux, host-сеть):

```bash
practice/mongo/docker/mongo-rs-up.sh
practice/mongo/docker/mongo-rs-init.sh
docker compose -f practice/mongo/docker/mongo-rs.compose.yml exec -it mongo1 mongosh --port 5571 demo
```

Остановка:

```bash
practice/mongo/docker/mongo-rs-down.sh
```

*(Опционально, для доклада)* наполнение `demo.orders`:

```bash
practice/mongo/docker/mongo-rs-seed.sh
```

Spring demo (`demo-mongo`) и replica set - для доклада. Домашка самодостаточна: любая MongoDB, см. [`HOMEWORK.md`](practice/mongo/HOMEWORK.md).

**macOS / Windows (стенд доклада):** `practice/mongo/docker/mongo-rs-up-bridge.sh` и `mongo-rs-init-bridge.sh`, либо WSL2.

---

## Замечания

- Если `docker compose up --wait` недоступен, используйте `up -d` и дождитесь готовности БД.
- При смене портов в `.env` обновите подключения в DBeaver / URI приложения.
