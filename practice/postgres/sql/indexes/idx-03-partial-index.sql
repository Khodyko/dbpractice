DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
    id BIGSERIAL PRIMARY KEY,
    status TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL
);

INSERT INTO orders (status, created_at)
SELECT
    CASE
        WHEN random() < 0.2 THEN 'PAID'
        WHEN random() < 0.7 THEN 'NEW'
        ELSE 'CANCELLED'
    END,
    now() - (random() * interval '365 days')
FROM generate_series(1, 500000);

CREATE INDEX idx_orders_paid_created_at
ON orders (created_at)
WHERE status = 'PAID';

EXPLAIN ANALYZE
SELECT * FROM orders
WHERE status = 'PAID'
  AND created_at > now() - interval '30 days';

EXPLAIN ANALYZE
SELECT * FROM orders
WHERE status = 'NEW'
  AND created_at > now() - interval '30 days';
