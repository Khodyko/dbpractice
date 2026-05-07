-- Кейс 2 (обязательный): та же нагрузка на distributed table.
-- Здесь таблица становится distributed только после явного create_distributed_table(...).
-- Это и есть переход от baseline без шардов (shard-01) к распределенной модели.
DROP TABLE IF EXISTS orders_dist CASCADE;

CREATE TABLE orders_dist (
    id BIGSERIAL,
    tenant_id INT NOT NULL,
    status TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    amount NUMERIC(12, 2) NOT NULL,
    PRIMARY KEY (tenant_id, id)
);

SELECT create_distributed_table('orders_dist', 'tenant_id');

CREATE INDEX idx_orders_dist_tenant_created
    ON orders_dist (tenant_id, created_at);

INSERT INTO orders_dist (tenant_id, status, created_at, amount)
SELECT
    (random() * 999)::INT,
    CASE WHEN random() < 0.8 THEN 'OPEN' ELSE 'CLOSED' END,
    now() - (random() * interval '180 days'),
    (random() * 10000)::NUMERIC(12, 2)
FROM generate_series(1, 2000000);

ANALYZE orders_dist;

EXPLAIN (ANALYZE, VERBOSE)
SELECT count(*)
FROM orders_dist
WHERE tenant_id = 42
  AND created_at >= now() - interval '30 days';
