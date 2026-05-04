DROP TABLE IF EXISTS events_flat CASCADE;
DROP TABLE IF EXISTS events_part CASCADE;
CREATE TABLE events_part (
    id BIGSERIAL,
    tenant_id INT NOT NULL,
    created_at DATE NOT NULL,
    payload TEXT NOT NULL
) PARTITION BY RANGE (created_at);

CREATE TABLE events_part_2025_01 PARTITION OF events_part
FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');
CREATE TABLE events_part_2025_02 PARTITION OF events_part
FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');
CREATE TABLE events_part_2025_03 PARTITION OF events_part
FOR VALUES FROM ('2025-03-01') TO ('2025-04-01');

-- Не менее 10 млн строк для наглядного pruning.
INSERT INTO events_part (tenant_id, created_at, payload)
SELECT (random() * 999)::INT, DATE '2025-01-01' + (gs % 90), md5(gs::text)
FROM generate_series(1, 10000000) gs;

ANALYZE events_part;

EXPLAIN ANALYZE
SELECT count(*)
FROM events_part
WHERE created_at >= DATE '2025-03-01'
  AND created_at < DATE '2025-04-01';
