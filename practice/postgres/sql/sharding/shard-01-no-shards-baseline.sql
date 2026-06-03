-- Кейс 1 (обязательный): baseline без шардов.
-- Важно: инициализированный Citus-кластер сам по себе не делает таблицу distributed.
-- Пока нет create_distributed_table(...), таблица остается локальной на coordinator.
DROP TABLE IF EXISTS orders_local CASCADE;

CREATE TABLE orders_local (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INT NOT NULL,
    status TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    amount NUMERIC(12, 2) NOT NULL
);

CREATE INDEX idx_orders_local_tenant_created
    ON orders_local (tenant_id, created_at);

INSERT INTO orders_local (tenant_id, status, created_at, amount)
SELECT
    (random() * 999)::INT,
    CASE WHEN random() < 0.8 THEN 'OPEN' ELSE 'CLOSED' END,
    now() - (random() * interval '180 days'),
    (random() * 10000)::NUMERIC(12, 2)
FROM generate_series(1, 2000000);

ANALYZE orders_local;

EXPLAIN (ANALYZE, VERBOSE)
SELECT count(*)
FROM orders_local
WHERE tenant_id = 42
  AND created_at >= now() - interval '30 days';
