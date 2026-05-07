# Практический стенд

Все команды `docker compose` ниже выполняются **из корня репозитория** (`dbSystemDesign`), если не указано иное. **SQL-скрипты из `practice/sql/` выполняются вручную** (например, в DBeaver: открыть файл или вставить текст в SQL Editor и выполнить).

Порты, имена БД, пользователь и пароль по умолчанию — в [`docker/.env.example`](practice/docker/.env.example). Если используете свой `practice/docker/.env`, возьмите значения оттуда же.

## Обзор по блокам

**Индексы**

- **Docker:** [`docker/indexes.compose.yml`](practice/docker/indexes.compose.yml) — один PostgreSQL на все кейсы `idx-01` … `idx-06`
- **SQL:** [`sql/indexes/`](sql/indexes/) — шесть файлов по очереди в **одной** БД

**Партиционирование**

- **Docker:** [`docker/partitions.compose.yml`](practice/docker/partitions.compose.yml) — один PostgreSQL на все кейсы `part-00` … `part-03`
- **SQL:** [`sql/partitioning/`](sql/partitioning/) — четыре файла по очереди в **одной** БД (каждый скрипт самодостаточен; рекомендуемый порядок — с `part-00`)

**Шардирование**

- **Docker:** [`docker/sharding.compose.yml`](practice/docker/sharding.compose.yml) — один Citus-кластер (coordinator + 3 worker) на все кейсы
- **SQL:** [`sql/sharding/`](sql/sharding/) — кейсы запускаются по очереди на coordinator; между кейсами выполнять reset

## Требования

- Docker и Docker Compose v2 (желательно с `docker compose up --wait`; иначе после `up -d` дождитесь готовности БД перед подключением клиентом)
- Клиент PostgreSQL: **DBeaver**, DataGrip, `psql` и т.п.

Переменные окружения: скопируйте [`docker/.env.example`](practice/docker/.env.example) в `docker/.env` при необходимости, либо передавайте `--env-file practice/docker/.env.example` в команды `docker compose`.

## Структура каталога `practice/`

- `docker/` — Compose-файлы и `.env.example`
- `sql/indexes/` — сценарии для индексов
- `sql/partitioning/` — сценарии для партиционирования
- `sql/sharding/` — сценарии для шардирования
- `sql/reset/` — общий сброс объектов (по необходимости)

---

## Подключение в DBeaver

Создайте подключения типа **PostgreSQL**. Хост — машина, где слушает контейнер (на той же машине, что и Docker, обычно `localhost` или `127.0.0.1`). SSL для локальных контейнеров обычно **выключен** (Disable).

Общие поля по умолчанию (из `.env.example`): **User** `demo`, **Password** `demo`.

| Блок / кейс | Host | Port | Database | Файлы SQL (вручную) |
|---------------|------|------|----------|---------------------|
| Индексы `idx-01` … `idx-06` | `localhost` | `5541` | `index_demo` | по очереди файлы `idx-01-selective-filter.sql` … `idx-06-stats-analyze.sql` в `sql/indexes/` |
| Партиции `part-00` … `part-03` | `localhost` | `5551` | `part_demo` | по очереди `part-00-no-partitioning-baseline.sql`, затем `part-01` … `part-03` в `sql/partitioning/` |
| Шардирование (Citus coordinator) | `localhost` | `5560` | `shard_demo` | сначала `shard-00-init-citus-cluster.sql`, далее кейсы `shard-01` ... `shard-06` (и опционально `shard-07`, `shard-08`) |
| Шардирование (worker 1, опционально) | `localhost` | `5561` | `shard_demo` | служебное подключение для диагностики |
| Шардирование (worker 2, опционально) | `localhost` | `5562` | `shard_demo` | служебное подключение для диагностики |
| Шардирование (worker 3, опционально) | `localhost` | `5563` | `shard_demo` | служебное подключение для диагностики |

В DBeaver для практики достаточно одного основного подключения к coordinator (`localhost:5560`) и, при необходимости, трёх служебных подключений к worker-нодам.

---

## Блок индексов (один compose, кейсы `idx-01` … `idx-06`)

1. Поднять PostgreSQL:

   ```bash
   docker compose -f practice/docker/indexes.compose.yml --env-file practice/docker/.env.example up -d --wait
   ```

2. В DBeaver подключиться к **localhost:5541**, БД **index_demo** (см. таблицу выше).

3. Вручную выполнить по очереди скрипты из `practice/sql/indexes/`: `idx-01-selective-filter.sql` … `idx-06-stats-analyze.sql`.

4. Остановить стенд:

   ```bash
   docker compose -f practice/docker/indexes.compose.yml --env-file practice/docker/.env.example down -v
   ```

---

## Партиционирование (один compose, кейсы `part-00` … `part-03`)

1. Поднять PostgreSQL:

   ```bash
   docker compose -f practice/docker/partitions.compose.yml --env-file practice/docker/.env.example up -d --wait
   ```

2. В DBeaver подключиться к **localhost:5551**, БД **part_demo** (см. таблицу выше).

3. Вручную выполнить по очереди скрипты из `practice/sql/partitioning/`:

   - `part-00-no-partitioning-baseline.sql` — одна таблица без партиций, тот же запрос `count(*)` по марту (сравнение времени с `part-01`);
   - `part-01-pruning-on.sql`
   - `part-02-pruning-off.sql`
   - `part-03-no-index-in-partitions.sql`

   В начале скриптов удаляются чужие объекты (`events_flat` / `events_part`), чтобы не копить два набора по 10 млн строк. Для сюжета доклада удобен порядок `00` → `01` → `02` → `03`.

4. Остановить стенд:

   ```bash
   docker compose -f practice/docker/partitions.compose.yml --env-file practice/docker/.env.example down -v
   ```

---

## Шардирование (один compose, Citus-кластер)

1. Поднять Citus-кластер:

   ```bash
   docker compose -f practice/docker/sharding.compose.yml --env-file practice/docker/.env.example up -d --wait
   ```

2. Подключиться в DBeaver к coordinator: **localhost:5560**, БД **shard_demo**.

3. Выполнить инициализацию кластера:

   - `practice/sql/sharding/shard-00-init-citus-cluster.sql`
   - Важно: этот шаг регистрирует worker-узлы у coordinator, но **не** делает все таблицы distributed автоматически.
     В Citus распределение включается отдельно для каждой таблицы (например, `SELECT create_distributed_table('orders_dist', 'tenant_id');`).

   Быстрая самопроверка после `shard-01`/`shard-02`:

   ```sql
   SELECT
       c.relname AS table_name,
       p.partmethod,
       pg_get_partkeydef(c.oid) AS distribution_key
   FROM pg_class c
   LEFT JOIN pg_dist_partition p ON p.logicalrelid = c.oid
   WHERE c.relname IN ('orders_local', 'orders_dist');
   ```

   Ожидаемо: `orders_local` без записи в `pg_dist_partition` (локальная таблица), `orders_dist` — с distribution key.

4. Выполнить обязательные кейсы (по очереди):

   - `practice/sql/sharding/shard-01-no-shards-baseline.sql`
   - `practice/sql/sharding/shard-02-distributed-performance.sql`
   - `practice/sql/sharding/shard-03-hot-spot-bad-shard-key.sql`
   - `practice/sql/sharding/shard-04-join-limitation-distributed.sql`
   - `practice/sql/sharding/shard-05-reference-table-join-fix.sql`
   - `practice/sql/sharding/shard-06-colocation-vs-non-colocation.sql`

5. Между кейсами запускать reset:

   - `practice/sql/reset/reset-all.sql`

6. Опциональные кейсы (если есть время):

   - `practice/sql/sharding/shard-07-optional-router-vs-distributed.sql`
   - `practice/sql/sharding/shard-08-optional-shard-skew-rebalance.sql`

7. Остановить стенд:

   ```bash
   docker compose -f practice/docker/sharding.compose.yml --env-file practice/docker/.env.example down -v
   ```

---

## Замечания

- Если `docker compose up --wait` недоступен, используйте `up -d` и подождите, пока PostgreSQL примет подключение, прежде чем открывать сессию в DBeaver.
- При смене портов или имён БД в `docker/.env` обновите и подключения в DBeaver, и таблицу (или сверяйтесь только с `.env`).
