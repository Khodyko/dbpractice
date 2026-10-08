# sync — физическая репликация (remote_apply)

Runbook: **[`REPLICA.md`](../../../REPLICA.md)** — раздел **sync**.

| Образец в репо | Когда |
|----------------|--------|
| [`conf/primary-bootstrap.conf`](conf/primary-bootstrap.conf) | PGDATA primary **до** sync (как async) |
| [`conf/primary.conf`](conf/primary.conf) | PGDATA primary **после** подключения standby |
| [`sql/init-primary.sql`](sql/init-primary.sql) | psql на primary |

Порты: **5580** / **5581** (остановите async на тех же портах).
