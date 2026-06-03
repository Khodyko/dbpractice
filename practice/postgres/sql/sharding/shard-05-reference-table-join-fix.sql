-- Кейс 5 (обязательный): reference table как решение JOIN.
DROP TABLE IF EXISTS orders_ref_demo CASCADE;
DROP TABLE IF EXISTS device_types_ref_demo CASCADE;

CREATE TABLE orders_ref_demo (
    id BIGSERIAL,
    tenant_id INT NOT NULL,
    device_type_id INT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    amount NUMERIC(12, 2) NOT NULL,
    PRIMARY KEY (tenant_id, id)
);

CREATE TABLE device_types_ref_demo (
    device_type_id INT PRIMARY KEY,
    device_type_name TEXT NOT NULL
);

SELECT create_distributed_table('orders_ref_demo', 'tenant_id');
SELECT create_reference_table('device_types_ref_demo');

INSERT INTO device_types_ref_demo (device_type_id, device_type_name)
SELECT s, 'type-' || s
FROM generate_series(1, 100) s;

INSERT INTO orders_ref_demo (tenant_id, device_type_id, created_at, amount)
SELECT
    (random() * 999)::INT,
    (1 + (random() * 99)::INT),
    now() - (random() * interval '180 days'),
    (random() * 10000)::NUMERIC(12, 2)
FROM generate_series(1, 1200000);

ANALYZE orders_ref_demo;
ANALYZE device_types_ref_demo;

EXPLAIN (ANALYZE, VERBOSE)
SELECT dt.device_type_name, count(*) AS orders_cnt
FROM orders_ref_demo o
JOIN device_types_ref_demo dt
  ON dt.device_type_id = o.device_type_id
WHERE o.tenant_id = 42
GROUP BY dt.device_type_name
ORDER BY orders_cnt DESC
LIMIT 5;
