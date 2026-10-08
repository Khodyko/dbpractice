# logical — логическая репликация

Runbook: **[`REPLICA.md`](../../../REPLICA.md)** — раздел **Logical** (7 шагов).

| Шаг | Файл |
|-----|------|
| 2 | [`conf/pg_hba.conf`](conf/pg_hba.conf) |
| 3 | [`sql/init-primary.sql`](sql/init-primary.sql) |
| 4 | [`sql/subscriber-setup.sql`](sql/subscriber-setup.sql) |
| 6 | [`sql/conflict-pk.sql`](sql/conflict-pk.sql) |

GUC: [`compose.yml`](compose.yml), образец [`conf/primary.conf`](conf/primary.conf). Порты **5580** / **5582**.
