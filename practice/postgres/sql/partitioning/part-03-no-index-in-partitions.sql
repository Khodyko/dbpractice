DROP TABLE IF EXISTS events_flat CASCADE;
DROP TABLE IF EXISTS events_part CASCADE;
CREATE TABLE events_part (
    id BIGSERIAL,
    tenant_id INT NOT NULL,
    created_at DATE NOT NULL,
    status TEXT NOT NULL
) PARTITION BY RANGE (created_at);

CREATE TABLE events_part_2025_01 PARTITION OF events_part
FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');
CREATE TABLE events_part_2025_02 PARTITION OF events_part
FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');
CREATE TABLE events_part_2025_03 PARTITION OF events_part
FOR VALUES FROM ('2025-03-01') TO ('2025-04-01');

-- Не менее 10 млн строк.
INSERT INTO events_part (tenant_id, created_at, status)
SELECT
    (random() * 999)::INT,
    DATE '2025-01-01' + (gs % 90),
    CASE WHEN random() < 0.8 THEN 'OPEN' ELSE 'CLOSED' END
FROM generate_series(1, 10000000) gs;

ANALYZE events_part;

EXPLAIN ANALYZE
SELECT *
FROM events_part
WHERE created_at >= DATE '2025-03-01'
  AND created_at < DATE '2025-04-01'
  AND status = 'CLOSED';

CREATE INDEX idx_events_part_status_created_at ON events_part (status, created_at);

EXPLAIN ANALYZE
SELECT *
FROM events_part
WHERE created_at >= DATE '2025-03-01'
  AND created_at < DATE '2025-04-01'
  AND status = 'CLOSED';
