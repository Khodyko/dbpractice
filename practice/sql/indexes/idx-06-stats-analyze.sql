DROP TABLE IF EXISTS orders_stats;
CREATE TABLE orders_stats (
    id BIGSERIAL PRIMARY KEY,
    status TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL
);

INSERT INTO orders_stats (status, created_at)
SELECT
    CASE WHEN gs <= 495000 THEN 'ACTIVE' ELSE 'ARCHIVED' END,
    now() - (random() * interval '365 days')
FROM generate_series(1, 500000) gs;

CREATE INDEX idx_orders_stats_status ON orders_stats (status);

EXPLAIN ANALYZE
SELECT * FROM orders_stats WHERE status = 'ARCHIVED';

UPDATE orders_stats
SET status = 'ARCHIVED'
WHERE id <= 300000;

EXPLAIN
SELECT * FROM orders_stats WHERE status = 'ARCHIVED';

ANALYZE orders_stats;

EXPLAIN ANALYZE
SELECT * FROM orders_stats WHERE status = 'ARCHIVED';
