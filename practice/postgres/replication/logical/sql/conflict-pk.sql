-- Один сценарий: локальная строка на subscriber, затем INSERT с primary с тем же PK.
\c postgresql://demo:demo@pg-subscriber:5432/repl_demo

INSERT INTO events (id, event_type, payload)
VALUES (42, 'local_row', 'inserted on subscriber');

\c postgresql://demo:demo@pg-primary:5432/repl_demo

INSERT INTO events (id, event_type, payload)
VALUES (42, 'from_primary', 'duplicate key on subscriber');

SELECT pg_sleep(3);

\c postgresql://demo:demo@pg-subscriber:5432/repl_demo

SELECT subname, pid, received_lsn, latest_end_lsn
FROM pg_stat_subscription;

SELECT id, event_type, payload FROM events WHERE id = 42 ORDER BY id;
