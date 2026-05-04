-- Опциональный кейс: router query vs distributed query.
DROP TABLE IF EXISTS orders_router_demo CASCADE;

CREATE TABLE orders_router_demo (
    id BIGSERIAL,
    tenant_id INT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    status TEXT NOT NULL,
    amount NUMERIC(12, 2) NOT NULL,
    PRIMARY KEY (tenant_id, id)
);

SELECT create_distributed_table('orders_router_demo', 'tenant_id');
CREATE INDEX idx_orders_router_tenant_created
    ON orders_router_demo (tenant_id, created_at);

INSERT INTO orders_router_demo (tenant_id, created_at, status, amount)
SELECT
    (random() * 999)::INT,
    now() - (random() * interval '180 days'),
    CASE WHEN random() < 0.8 THEN 'OPEN' ELSE 'CLOSED' END,
    (random() * 10000)::NUMERIC(12, 2)
FROM generate_series(1, 1500000);

ANALYZE orders_router_demo;

-- Router query: точечный запрос по distribution key.
EXPLAIN (ANALYZE, VERBOSE)
SELECT count(*)
FROM orders_router_demo
WHERE tenant_id = 42
  AND created_at >= now() - interval '30 days';

-- Distributed query: fan-out без фильтра по distribution key.
EXPLAIN (ANALYZE, VERBOSE)
SELECT count(*)
FROM orders_router_demo
WHERE created_at >= now() - interval '30 days';
