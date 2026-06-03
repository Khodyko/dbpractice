-- Кейс 3 (обязательный): HOT SPOT при плохом ключе шардирования.
DROP TABLE IF EXISTS orders_hotspot CASCADE;

CREATE TABLE orders_hotspot (
    id BIGSERIAL,
    tenant_id INT NOT NULL,
    region_id INT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    amount NUMERIC(12, 2) NOT NULL,
    PRIMARY KEY (region_id, id)
);

-- Плохой key: низкая кардинальность (всего 3 региона).
SELECT create_distributed_table('orders_hotspot', 'region_id');

INSERT INTO orders_hotspot (tenant_id, region_id, created_at, amount)
SELECT
    (random() * 999)::INT,
    CASE
        WHEN random() < 0.85 THEN 1
        WHEN random() < 0.95 THEN 2
        ELSE 3
    END,
    now() - (random() * interval '180 days'),
    (random() * 10000)::NUMERIC(12, 2)
FROM generate_series(1, 1500000);

ANALYZE orders_hotspot;

-- Смотрим перекос по распределительному ключу.
SELECT region_id, count(*) AS rows_cnt
FROM orders_hotspot
GROUP BY region_id
ORDER BY rows_cnt DESC;

EXPLAIN (ANALYZE, VERBOSE)
SELECT count(*)
FROM orders_hotspot
WHERE region_id = 1;
