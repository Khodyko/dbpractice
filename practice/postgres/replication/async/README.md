# async — физическая репликация (async)

Runbook: **[`REPLICA.md`](../../../REPLICA.md)** — раздел **async**.

| Образец в репо | Куда на стенде |
|----------------|----------------|
| [`conf/primary.conf`](conf/primary.conf), [`conf/pg_hba.conf`](conf/pg_hba.conf) | `/var/lib/postgresql/data/postgresql.conf`, `pg_hba.conf` на **pg-primary** |
| [`sql/init-primary.sql`](sql/init-primary.sql) | набрать в psql на primary |
| [`sql/bench-insert.sql`](sql/bench-insert.sql) | строка для pgbench (см. REPLICA) |
| basebackup | команды в **REPLICA.md** (async, шаг 4), shell **pg-standby** |

Порты: **5580** (primary), **5581** (standby).
