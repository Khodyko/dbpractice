-- Опционально: GUC и pg_stat_* после настройки стенда (см. REPLICA.md).
-- С хоста (DBeaver): localhost:5580 / 5581

\timing on

\echo '=== Primary: ключевые GUC ==='
SHOW wal_level;
SHOW max_wal_senders;
SHOW max_replication_slots;
SHOW hot_standby;
SHOW synchronous_commit;
SHOW synchronous_standby_names;

\echo '=== Primary: pg_stat_replication ==='
SELECT application_name, state, sync_state, write_lag, flush_lag, replay_lag
FROM pg_stat_replication;

\echo '=== Primary: pg_replication_slots ==='
SELECT slot_name, slot_type, active, restart_lsn
FROM pg_replication_slots;

\echo '=== Standby: pg_is_in_recovery (ожидаем true) ==='
\c postgresql://demo:demo@pg-standby:5432/repl_demo
SELECT pg_is_in_recovery() AS in_recovery;

\echo '=== Standby: recovery GUC (фрагмент) ==='
SELECT name, setting
FROM pg_settings
WHERE name IN ('primary_conninfo', 'primary_slot_name', 'hot_standby')
ORDER BY name;

-- Шпаргалка sync-режимов (PG 17 Table 19.1):
-- async: standby_names='', commit=local — только flush на primary.
-- remote_write / on / remote_apply: нужен non-empty synchronous_standby_names.
-- remote_write — standby принял WAL; on — flush на диск standby; remote_apply — replay на standby.
