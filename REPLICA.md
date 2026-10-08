# PostgreSQL: репликация (runbook доклада)

Runbook для доклада и [домашки по репликации](practice/postgres/HOMEWORK.md#4-репликация). Команды — **из корня репозитория**.

Порт **5580** один на async / sync / logical — стенды **не параллельно**.

- Compose async: `practice/postgres/replication/async/compose.yml`
- Compose sync: `practice/postgres/replication/sync/compose.yml`
- Compose logical: `practice/postgres/replication/logical/compose.yml`

Подключение с хоста: `demo` / `demo`, база `repl_demo`, порты **5580** (primary), **5581** (standby), **5582** (subscriber).


Файлы из репозитория **не смонтированы** в контейнер — текст копируете из IDE (conf, sql).

### Имена на стенде (не менять между async / sync / logical)

| Имя | Где используется |
|-----|------------------|
| База `repl_demo` | все инстансы |
| Приложение `demo` / пароль `demo` | вход в psql, DBeaver |
| Роль **`repluser`** / пароль **`replpass`** | `init-primary.sql`, `pg_basebackup`, logical subscription |
| Слот **`standby1_slot`** | SQL на primary, `pg_basebackup -S standby1_slot` |
| **`application_name=standby1`** | `postgresql.auto.conf` на standby после basebackup; строка в `pg_stat_replication.application_name` |
| **`synchronous_standby_names = 'standby1'`** | только sync в `postgresql.conf` primary — **должно совпадать** с `application_name` |
| Сервис Docker **`pg-primary`** | hostname в compose-сети для basebackup и logical |
| Сервис **`pg-standby`** | async/sync |
| Сервис **`pg-subscriber`** | logical |
| Publication **`events_only`** | logical, таблица **`events`** |
| Subscription **`events_sub`** | logical на subscriber |
| Таблица **`bench_write`** | async/sync pgbench |

---

## Async

### 1. Поднять primary

```shell
docker compose -f practice/postgres/replication/async/compose.yml up -d pg-primary --wait
```

Файлы не нужны.

### 2. Конфиг primary

**Файлы** (внутри контейнера, каталог PGDATA):

- [`practice/postgres/replication/async/conf/primary.conf`](practice/postgres/replication/async/conf/primary.conf) → дописать в `/var/lib/postgresql/data/postgresql.conf`
- [`practice/postgres/replication/async/conf/pg_hba.conf`](practice/postgres/replication/async/conf/pg_hba.conf) → строку `host replication …` дописать в `/var/lib/postgresql/data/pg_hba.conf` (остальное hba можно не трогать)

```shell
docker compose -f practice/postgres/replication/async/compose.yml exec -u root -it pg-primary bash
```

Внутри (один заход): `apt-get update`, `apt-get install -y vim-tiny`, правка conf по файлам выше, `exit`.

После смены **`wal_level`** — перезапуск primary:

```shell
docker compose -f practice/postgres/replication/async/compose.yml restart pg-primary
docker compose -f practice/postgres/replication/async/compose.yml up -d pg-primary --wait
```

### 3. Роли, слот, таблица

**Файл:** [`practice/postgres/replication/async/sql/init-primary.sql`](practice/postgres/replication/async/sql/init-primary.sql) — роль **`repluser`**, слот **`standby1_slot`**, таблица **`bench_write`**.

```shell
docker compose -f practice/postgres/replication/async/compose.yml exec -it pg-primary psql -U demo -d repl_demo
```

Скопировать SQL из файла, затем `\q`.

### 4. Standby: pg_basebackup

На primary уже должны быть **`repluser`**, слот **`standby1_slot`** (шаг 3).

Каталог данных standby: `/var/lib/postgresql/data` (очистка — первой командой в bash ниже).

```shell
docker compose -f practice/postgres/replication/async/compose.yml up -d pg-standby
docker compose -f practice/postgres/replication/async/compose.yml exec -it pg-standby bash
```

В том же bash — очистка PGDATA, затем basebackup:

```bash
rm -rf /var/lib/postgresql/data/*
PGPASSWORD=replpass pg_basebackup -h pg-primary -p 5432 -U repluser \
  -D /var/lib/postgresql/data -Fp -Xs -P -R -S standby1_slot
exit
```

**Async:** для шага 5 достаточно basebackup; имя **`standby1`** в `pg_stat_replication` необязательно (можно добавить ниже перед sync).

**Перед sync** (или если в проверке нужно именно `application_name = standby1`) — один раз после basebackup:

```bash
grep -q 'application_name=standby1' /var/lib/postgresql/data/postgresql.auto.conf || \
  sed -i '/primary_conninfo/s/port=5432/port=5432 application_name=standby1/' \
  /var/lib/postgresql/data/postgresql.auto.conf
```

Без слота: уберите `-S standby1_slot` и строку слота из `init-primary.sql`.

После basebackup (и при необходимости `sed`) — запуск postgres на standby:

```shell
docker compose -f practice/postgres/replication/async/compose.yml restart pg-standby
docker compose -f practice/postgres/replication/async/compose.yml up -d pg-standby --wait
```

### 5. Проверка репликации

```shell
docker compose -f practice/postgres/replication/async/compose.yml exec -T pg-primary psql -U demo -d repl_demo -c "SELECT application_name, sync_state FROM pg_stat_replication;"
```

Ожидание: `sync_state = async`; в колонке `application_name` — **`standby1`**, если выполняли `sed` выше (иначе может быть другое имя — для async это нормально).

### 6. Одна запись (проверка до бенча)

**Файл:** [`practice/postgres/replication/async/sql/bench-insert.sql`](practice/postgres/replication/async/sql/bench-insert.sql) — одна строка `INSERT`.

```shell
docker compose -f practice/postgres/replication/async/compose.yml exec -T pg-primary psql -U demo -d repl_demo -c "INSERT INTO bench_write (payload) VALUES (md5(random()::text));"
docker compose -f practice/postgres/replication/async/compose.yml exec -T pg-standby psql -U demo -d repl_demo -c "SELECT count(*) AS rows_on_standby FROM bench_write;"
```

На standby `rows_on_standby` должен совпадать с primary (после async — обычно сразу или через секунду).

### 7. Бенч (опционально)

**Файл:** та же строка из [`bench-insert.sql`](practice/postgres/replication/async/sql/bench-insert.sql) (в команде ниже уже подставлена).

```shell
docker compose -f practice/postgres/replication/async/compose.yml exec -T pg-primary bash -c 'echo "INSERT INTO bench_write (payload) VALUES (md5(random()::text));" > /tmp/bench.sql && pgbench -U demo -d repl_demo -n -c 1 -T 20 -f /tmp/bench.sql'
```

### 8. Стоп

```shell
docker compose -f practice/postgres/replication/async/compose.yml down -v
```

---

## Sync

Сначала physical standby **как async** (commit не ждёт replica). Потом на primary включаете **`synchronous_standby_names = 'standby1'`** и **`remote_apply`**. Async-стенд на 5580/5581 должен быть остановлен (`down -v`).

Compose: `practice/postgres/replication/sync/compose.yml`

### 1. Поднять primary

```shell
docker compose -f practice/postgres/replication/sync/compose.yml up -d pg-primary --wait
```

Файлы не нужны.

### 2. Конфиг primary (режим «до sync», как async)

**Файлы** (PGDATA на pg-primary):

- [`practice/postgres/replication/sync/conf/primary-bootstrap.conf`](practice/postgres/replication/sync/conf/primary-bootstrap.conf) → дописать в `/var/lib/postgresql/data/postgresql.conf` (пустой `synchronous_standby_names`, `synchronous_commit = local`)
- [`practice/postgres/replication/sync/conf/pg_hba.conf`](practice/postgres/replication/sync/conf/pg_hba.conf) → строку `host replication …` в `/var/lib/postgresql/data/pg_hba.conf`

```shell
docker compose -f practice/postgres/replication/sync/compose.yml exec -u root -it pg-primary bash
```

`apt-get update`, `apt-get install -y vim-tiny`, правка conf, `exit`.

```shell
docker compose -f practice/postgres/replication/sync/compose.yml restart pg-primary
docker compose -f practice/postgres/replication/sync/compose.yml up -d pg-primary --wait
```

### 3. Роли, слот, таблица

**Файл:** [`practice/postgres/replication/sync/sql/init-primary.sql`](practice/postgres/replication/sync/sql/init-primary.sql) — **`repluser`**, **`standby1_slot`**, **`bench_write`**.

```shell
docker compose -f practice/postgres/replication/sync/compose.yml exec -it pg-primary psql -U demo -d repl_demo
```

Скопировать SQL, `\q`.

### 4. Standby: pg_basebackup и имя standby1

На primary: **`repluser`**, **`standby1_slot`**.

```shell
docker compose -f practice/postgres/replication/sync/compose.yml up -d pg-standby
docker compose -f practice/postgres/replication/sync/compose.yml exec -it pg-standby bash
```

```bash
rm -rf /var/lib/postgresql/data/*
PGPASSWORD=replpass pg_basebackup -h pg-primary -p 5432 -U repluser \
  -D /var/lib/postgresql/data -Fp -Xs -P -R -S standby1_slot
grep -q 'application_name=standby1' /var/lib/postgresql/data/postgresql.auto.conf || \
  sed -i '/primary_conninfo/s/port=5432/port=5432 application_name=standby1/' \
  /var/lib/postgresql/data/postgresql.auto.conf
exit
```

Для sync **`application_name=standby1`** обязателен (совпадает с `synchronous_standby_names` на шаге 6).

```shell
docker compose -f practice/postgres/replication/sync/compose.yml restart pg-standby
docker compose -f practice/postgres/replication/sync/compose.yml up -d pg-standby --wait
```

### 5. Проверка до включения sync

```shell
docker compose -f practice/postgres/replication/sync/compose.yml exec -T pg-primary psql -U demo -d repl_demo -c "SHOW synchronous_commit; SELECT application_name, sync_state FROM pg_stat_replication;"
```

Ожидание: `synchronous_commit = local`, **`application_name = standby1`**, **`sync_state = async`**.

### 6. Включить sync на primary

**Файл:** [`practice/postgres/replication/sync/conf/primary.conf`](practice/postgres/replication/sync/conf/primary.conf) → в `/var/lib/postgresql/data/postgresql.conf` **заменить** строки sync:

```ini
synchronous_standby_names = 'standby1'
synchronous_commit = remote_apply
```

```shell
docker compose -f practice/postgres/replication/sync/compose.yml exec -u root -it pg-primary bash
```

Правка `postgresql.conf`, `exit`.

```shell
docker compose -f practice/postgres/replication/sync/compose.yml restart pg-primary
docker compose -f practice/postgres/replication/sync/compose.yml up -d pg-primary --wait
```

### 7. Проверка sync

```shell
docker compose -f practice/postgres/replication/sync/compose.yml exec -T pg-primary psql -U demo -d repl_demo -c "SHOW synchronous_commit; SELECT application_name, sync_state FROM pg_stat_replication;"
```

Ожидание: **`synchronous_commit = remote_apply`**, **`application_name = standby1`**, **`sync_state = sync`**.

### 8. Одна запись (проверка до бенча)

**Файл:** [`practice/postgres/replication/sync/sql/bench-insert.sql`](practice/postgres/replication/sync/sql/bench-insert.sql) — одна строка `INSERT`.

```shell
docker compose -f practice/postgres/replication/sync/compose.yml exec -T pg-primary psql -U demo -d repl_demo -c "INSERT INTO bench_write (payload) VALUES (md5(random()::text));"
docker compose -f practice/postgres/replication/sync/compose.yml exec -T pg-standby psql -U demo -d repl_demo -c "SELECT count(*) AS rows_on_standby FROM bench_write;"
```

В режиме sync строка на standby появляется до ответа `INSERT` на primary (commit ждёт replica).

### 9. Бенч (опционально)

**Файл:** та же строка из [`bench-insert.sql`](practice/postgres/replication/sync/sql/bench-insert.sql).

```shell
docker compose -f practice/postgres/replication/sync/compose.yml exec -T pg-primary bash -c 'echo "INSERT INTO bench_write (payload) VALUES (md5(random()::text));" > /tmp/bench.sql && pgbench -U demo -d repl_demo -n -c 1 -T 20 -f /tmp/bench.sql'
```

На sync N в pgbench обычно **меньше**, чем на async (primary ждёт standby).

### 10. Стоп

```shell
docker compose -f practice/postgres/replication/sync/compose.yml down -v
```

---

## Logical

Схема как в [обзоре OTUS на Habr](https://habr.com/ru/companies/otus/articles/710956/): **`wal_level=logical`**, на master **publication**, на replica **subscription**, INSERT на master → строка на subscriber. Без дампа: схема на subscriber вручную, `copy_data=true` подтягивает данные при создании subscription.

Compose: `practice/postgres/replication/logical/compose.yml` (**`wal_level`** уже в command). Образец GUC: [`conf/primary.conf`](practice/postgres/replication/logical/conf/primary.conf). Порт **5580** не делите с async/sync.

Команды — из **корня репозитория**.

### 1. Поднять стенд

```shell
docker compose -f practice/postgres/replication/logical/compose.yml down -v
docker compose -f practice/postgres/replication/logical/compose.yml up -d --wait
```

### 2. Доступ replication с subscriber (pg_hba)

**Файл:** [`conf/pg_hba.conf`](practice/postgres/replication/logical/conf/pg_hba.conf).

```shell
docker compose -f practice/postgres/replication/logical/compose.yml exec -u root -T pg-primary bash -c 'cat > /var/lib/postgresql/data/pg_hba.conf' \
  < practice/postgres/replication/logical/conf/pg_hba.conf
docker compose -f practice/postgres/replication/logical/compose.yml exec -T pg-primary psql -U demo -d repl_demo -c "SELECT pg_reload_conf();"
```

### 3. Master: publication

**Файл:** [`init-primary.sql`](practice/postgres/replication/logical/sql/init-primary.sql) — **`repluser`**, таблица **`events`**, **`CREATE PUBLICATION events_only`**.

```shell
docker compose -f practice/postgres/replication/logical/compose.yml exec -T pg-primary psql -U demo -d repl_demo -v ON_ERROR_STOP=1 \
  < practice/postgres/replication/logical/sql/init-primary.sql
```

### 4. Replica: subscription

**Файл:** [`subscriber-setup.sql`](practice/postgres/replication/logical/sql/subscriber-setup.sql) — с **pg-primary** (`\c` на **`pg-subscriber`**): таблица **`events`**, **`CREATE SUBSCRIPTION events_sub`**.

```shell
docker compose -f practice/postgres/replication/logical/compose.yml exec -T pg-primary psql -U demo -d repl_demo -v ON_ERROR_STOP=1 \
  < practice/postgres/replication/logical/sql/subscriber-setup.sql
```

### 5. Данные и проверка

```shell
docker compose -f practice/postgres/replication/logical/compose.yml exec -T pg-primary psql -U demo -d repl_demo -c \
  "INSERT INTO events (id, event_type, payload) VALUES (1, 'order_created', 'demo');"
docker compose -f practice/postgres/replication/logical/compose.yml exec -T pg-subscriber psql -U demo -d repl_demo -c \
  "SELECT id, event_type, payload FROM events ORDER BY id;"
```

Ожидание: на subscriber та же строка `id=1` (если сразу пусто — подождите 1–2 с и повторите SELECT).

### 6. Конфликт PK (duplicate key)

**Файл:** [`conflict-pk.sql`](practice/postgres/replication/logical/sql/conflict-pk.sql) — с **pg-primary**: локальная строка на subscriber, INSERT с тем же **`id=42`**, пауза, проверка.

```shell
docker compose -f practice/postgres/replication/logical/compose.yml exec -T pg-primary psql -U demo -d repl_demo -v ON_ERROR_STOP=1 \
  < practice/postgres/replication/logical/sql/conflict-pk.sql
docker compose -f practice/postgres/replication/logical/compose.yml logs pg-subscriber | tail -20
```

Ожидание: у **`events_sub`** пустой **`pid`**; в логах — `duplicate key` по **`events_pkey`**; на subscriber для `id=42` только **`local_row`**.

### 7. Стоп

```shell
docker compose -f practice/postgres/replication/logical/compose.yml down -v
```

---

## Дополнительно (не обязательно на live)

- Диагностика GUC и `pg_stat_replication` / subscription: [`practice/postgres/replication/sql/repl-00-constants-and-status.sql`](practice/postgres/replication/sql/repl-00-constants-and-status.sql)
