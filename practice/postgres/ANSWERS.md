# ANSWERS: PostgreSQL

Как выполнить [HOMEWORK.md](HOMEWORK.md). Ниже - стенды из репозитория и готовые SQL. Логин/пароль: `demo` / `demo`, SSL **Disable**.

Команды Docker - из корня репозитория.

---

## 1. Индексы

| Порт | База |
|------|------|
| 5541 | `index_demo` |

```bash
docker compose -f practice/postgres/docker/indexes.compose.yml \
  --env-file practice/postgres/docker/.env.example up -d --wait
```

Готовые кейсы (по одному файлу): [`sql/indexes/`](sql/indexes/)

| Кейс | Скрипт | Что увидеть на практике |
|------|--------|-------------------------|
| email до/после индекса | [`idx-01-selective-filter.sql`](sql/indexes/idx-01-selective-filter.sql) | без индекса: Seq Scan; с индексом: Index Scan или Bitmap Index Scan |
| частый vs редкий status | [`idx-02-low-selectivity.sql`](sql/indexes/idx-02-low-selectivity.sql) | после `ANALYZE`: `ACTIVE` → Seq Scan, `ARCHIVED` → Index Scan |
| частичный индекс | [`idx-03-partial-index.sql`](sql/indexes/idx-03-partial-index.sql) | `PAID` → индекс `idx_orders_paid_created_at`; `NEW` → Seq Scan |
| порядок колонок | [`idx-04-composite-order.sql`](sql/indexes/idx-04-composite-order.sql) | `(tenant_id, created_at)` + оба фильтра → индекс; только `created_at` → Seq Scan; после `(created_at, tenant_id)` → индекс |
| `lower(email)` | [`idx-05-non-sargable.sql`](sql/indexes/idx-05-non-sargable.sql) | на таблице `users_demo`: обычный индекс по `email` не помогает; `((lower(email)))` → Bitmap Index Scan |

```bash
docker compose -f practice/postgres/docker/indexes.compose.yml \
  --env-file practice/postgres/docker/.env.example down -v
```

---

## 2. Партиции

| Порт | База |
|------|------|
| 5551 | `part_demo` |

```bash
docker compose -f practice/postgres/docker/partitions.compose.yml \
  --env-file practice/postgres/docker/.env.example up -d --wait
```

Скрипт: [`sql/homework/hw-part-bad-key.sql`](sql/homework/hw-part-bad-key.sql)

В плане: `Parallel Append` и Seq Scan по **всем** партициям `events_r1`, `events_r2`, `events_r3` - pruning нет.

**Вопрос:** почему медленно? Что с ключом?

**Ответ:** ключ партиционирования выбран неверно - таблица разбита по `region_id`, а запрос фильтрует по `created_at`. Pruning не работает, сканируются все партиции; регион 1 ещё и перегружен (hot spot).

Правильнее партиционировать по `created_at` (или другому полю из типичного `WHERE`).

```bash
docker compose -f practice/postgres/docker/partitions.compose.yml \
  --env-file practice/postgres/docker/.env.example down -v
```

---

## 3. Citus

| Порт | База |
|------|------|
| 5560 | `shard_demo` (coordinator) |

```bash
docker compose -f practice/postgres/docker/sharding.compose.yml \
  --env-file practice/postgres/docker/.env.example up -d --wait
```

Инициализация нод: [`sql/sharding/shard-00-init-citus-cluster.sql`](sql/sharding/shard-00-init-citus-cluster.sql)

| Соединение | Скрипт | Ожидание |
|------------|--------|----------|
| colocated JOIN | [`shard-06-colocation-vs-non-colocation.sql`](sql/sharding/shard-06-colocation-vs-non-colocation.sql) (первый `SELECT`) | выполняется |
| reference JOIN | [`shard-05-reference-table-join-fix.sql`](sql/sharding/shard-05-reference-table-join-fix.sql) | выполняется |
| JOIN с разными ключами | второй `SELECT` в [`shard-06`](sql/sharding/shard-06-colocation-vs-non-colocation.sql) или [`shard-04`](sql/sharding/shard-04-join-limitation-distributed.sql) | без отключения repartition Citus **может выполнить** JOIN дорого; для явной ошибки нужен `SET` ниже |

Перед «плохим» JOIN обязательно:

```sql
SET citus.enable_repartition_joins TO off;
```

Ошибка вида: `the query contains a join that requires repartitioning`.

```bash
docker compose -f practice/postgres/docker/sharding.compose.yml \
  --env-file practice/postgres/docker/.env.example down -v
```
