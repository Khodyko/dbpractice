-- Кейс 4 (обязательный): ограничения JOIN distributed-таблиц.
DROP TABLE IF EXISTS orders_join_demo CASCADE;
DROP TABLE IF EXISTS devices_join_demo CASCADE;

CREATE TABLE orders_join_demo (
    id BIGSERIAL,
    tenant_id INT NOT NULL,
    device_id BIGINT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (tenant_id, id)
);

CREATE TABLE devices_join_demo (
    id BIGSERIAL,
    device_id BIGINT NOT NULL,
    device_type_id INT NOT NULL,
    PRIMARY KEY (device_id, id)
);

SELECT create_distributed_table('orders_join_demo', 'tenant_id');
SELECT create_distributed_table('devices_join_demo', 'device_id');

INSERT INTO orders_join_demo (tenant_id, device_id, created_at)
SELECT
    (random() * 999)::INT,
    (random() * 100000)::BIGINT,
    now() - (random() * interval '30 days')
FROM generate_series(1, 500000);

INSERT INTO devices_join_demo (device_id, device_type_id)
SELECT
    s,
    (random() * 20)::INT
FROM generate_series(1, 100000) s;

ANALYZE orders_join_demo;
ANALYZE devices_join_demo;

-- В зависимости от версии Citus этот JOIN может дать ошибку
-- или очень дорогой repartition plan.
EXPLAIN (ANALYZE, VERBOSE)
SELECT count(*)
FROM orders_join_demo o
JOIN devices_join_demo d
  ON d.device_id = o.device_id
WHERE o.tenant_id = 42;
