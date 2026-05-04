-- Бейзлайн: одна таблица без партиций, тот же объём и распределение дат, что в part-01.
-- Выполнять первым; затем part-01 для сравнения времени и плана (pruning).

DROP TABLE IF EXISTS events_part CASCADE;
DROP TABLE IF EXISTS events_flat CASCADE;
CREATE TABLE events_flat (
    id BIGSERIAL,
    tenant_id INT NOT NULL,
    created_at DATE NOT NULL,
    payload TEXT NOT NULL
);

INSERT INTO events_flat (tenant_id, created_at, payload)
SELECT (random() * 999)::INT, DATE '2025-01-01' + (gs % 90), md5(gs::text)
FROM generate_series(1, 10000000) gs;

ANALYZE events_flat;

EXPLAIN ANALYZE
SELECT count(*)
FROM events_flat
WHERE created_at >= DATE '2025-03-01'
  AND created_at < DATE '2025-04-01';
