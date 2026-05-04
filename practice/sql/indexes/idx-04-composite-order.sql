DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INT NOT NULL,
    created_at TIMESTAMP NOT NULL
);

INSERT INTO orders (tenant_id, created_at)
SELECT
    (random() * 999)::INT + 1,
    now() - (random() * interval '365 days')
FROM generate_series(1, 500000);

CREATE INDEX idx_orders_tenant_created ON orders (tenant_id, created_at);

EXPLAIN ANALYZE
SELECT * FROM orders
WHERE tenant_id = 42
  AND created_at >= now() - interval '7 days';

EXPLAIN ANALYZE
SELECT * FROM orders
WHERE created_at >= now() - interval '7 days';

CREATE INDEX idx_orders_created_tenant ON orders (created_at, tenant_id);

EXPLAIN ANALYZE
SELECT * FROM orders
WHERE created_at >= now() - interval '7 days';
