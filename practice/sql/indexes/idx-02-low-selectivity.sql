DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
    id BIGSERIAL PRIMARY KEY,
    status TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL
);

INSERT INTO orders (status, created_at)
SELECT
    CASE WHEN random() < 0.95 THEN 'ACTIVE' ELSE 'ARCHIVED' END,
    now() - (random() * interval '365 days')
FROM generate_series(1, 500000);

CREATE INDEX idx_orders_status ON orders (status);

EXPLAIN ANALYZE
SELECT * FROM orders WHERE status = 'ACTIVE';

EXPLAIN ANALYZE
SELECT * FROM orders WHERE status = 'ARCHIVED';
