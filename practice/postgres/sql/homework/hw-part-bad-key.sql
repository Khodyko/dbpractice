-- HOMEWORK: партиционирование и запрос по дате.
-- База part_demo (или своя). ~1M events, LIST по region_id, перекос в регион 1.

DROP TABLE IF EXISTS events CASCADE;

CREATE TABLE events (
    id          BIGSERIAL,
    region_id   INT NOT NULL,
    created_at  DATE NOT NULL,
    payload     TEXT NOT NULL
) PARTITION BY LIST (region_id);

CREATE TABLE events_r1 PARTITION OF events FOR VALUES IN (1);
CREATE TABLE events_r2 PARTITION OF events FOR VALUES IN (2);
CREATE TABLE events_r3 PARTITION OF events FOR VALUES IN (3);

INSERT INTO events (region_id, created_at, payload)
SELECT
    CASE
        WHEN random() < 0.85 THEN 1
        WHEN random() < 0.95 THEN 2
        ELSE 3
    END,
    DATE '2025-01-01' + (gs % 90),
    md5(gs::text)
FROM generate_series(1, 1000000) gs;

ANALYZE events;

-- Кейс: фильтр по дате при ключе region_id → все партиции в плане
EXPLAIN ANALYZE
SELECT count(*)
FROM events
WHERE created_at >= DATE '2025-03-01'
  AND created_at < DATE '2025-04-01';
