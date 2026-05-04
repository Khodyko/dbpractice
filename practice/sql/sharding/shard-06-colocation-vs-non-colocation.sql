-- Кейс 6 (обязательный): co-location vs non-colocation.
DROP TABLE IF EXISTS orders_colocated_demo CASCADE;
DROP TABLE IF EXISTS payments_colocated_demo CASCADE;
DROP TABLE IF EXISTS payments_non_colocated_demo CASCADE;

CREATE TABLE orders_colocated_demo (
    id BIGSERIAL,
    tenant_id INT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    amount NUMERIC(12, 2) NOT NULL,
    PRIMARY KEY (tenant_id, id)
);

CREATE TABLE payments_colocated_demo (
    id BIGSERIAL,
    tenant_id INT NOT NULL,
    order_id BIGINT NOT NULL,
    status TEXT NOT NULL,
    PRIMARY KEY (tenant_id, id)
);

CREATE TABLE payments_non_colocated_demo (
    id BIGSERIAL,
    payment_provider_id INT NOT NULL,
    order_id BIGINT NOT NULL,
    status TEXT NOT NULL,
    PRIMARY KEY (payment_provider_id, id)
);

SELECT create_distributed_table('orders_colocated_demo', 'tenant_id');
SELECT create_distributed_table(
    'payments_colocated_demo',
    'tenant_id',
    colocate_with := 'orders_colocated_demo'
);
SELECT create_distributed_table('payments_non_colocated_demo', 'payment_provider_id');

INSERT INTO orders_colocated_demo (tenant_id, created_at, amount)
SELECT
    (random() * 999)::INT,
    now() - (random() * interval '60 days'),
    (random() * 10000)::NUMERIC(12, 2)
FROM generate_series(1, 800000);

INSERT INTO payments_colocated_demo (tenant_id, order_id, status)
SELECT
    tenant_id,
    id,
    CASE WHEN random() < 0.9 THEN 'PAID' ELSE 'FAILED' END
FROM orders_colocated_demo;

INSERT INTO payments_non_colocated_demo (payment_provider_id, order_id, status)
SELECT
    (1 + (random() * 4)::INT),
    id,
    CASE WHEN random() < 0.9 THEN 'PAID' ELSE 'FAILED' END
FROM orders_colocated_demo;

ANALYZE orders_colocated_demo;
ANALYZE payments_colocated_demo;
ANALYZE payments_non_colocated_demo;

-- Хороший JOIN: co-located таблицы по tenant_id.
EXPLAIN (ANALYZE, VERBOSE)
SELECT count(*)
FROM orders_colocated_demo o
JOIN payments_colocated_demo p
  ON p.tenant_id = o.tenant_id
 AND p.order_id = o.id
WHERE o.tenant_id = 42;

-- Плохой JOIN: non-colocated таблицы.
EXPLAIN (ANALYZE, VERBOSE)
SELECT count(*)
FROM orders_colocated_demo o
JOIN payments_non_colocated_demo p
  ON p.order_id = o.id
WHERE o.tenant_id = 42;
