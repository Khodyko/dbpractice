-- Опциональный кейс: shard skew + rebalancing.
DROP TABLE IF EXISTS events_skew_demo CASCADE;

CREATE TABLE events_skew_demo (
    id BIGSERIAL,
    tenant_id INT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    payload TEXT NOT NULL,
    PRIMARY KEY (tenant_id, id)
);

SELECT create_distributed_table('events_skew_demo', 'tenant_id');

-- Сильно перекошенный поток: tenant_id = 1 получает 80% строк.
INSERT INTO events_skew_demo (tenant_id, created_at, payload)
SELECT
    CASE WHEN random() < 0.8 THEN 1 ELSE (2 + (random() * 998)::INT) END,
    now() - (random() * interval '30 days'),
    md5(random()::text)
FROM generate_series(1, 1500000);

ANALYZE events_skew_demo;

-- До ребаланса.
SELECT tenant_id, count(*) AS rows_cnt
FROM events_skew_demo
GROUP BY tenant_id
ORDER BY rows_cnt DESC
LIMIT 10;

-- В зависимости от версии Citus используйте одну из функций:
-- SELECT rebalance_table_shards('events_skew_demo');
-- SELECT citus_rebalance_start();

-- После ребаланса повторить диагностику и сравнить план/время.
EXPLAIN (ANALYZE, VERBOSE)
SELECT count(*)
FROM events_skew_demo
WHERE created_at >= now() - interval '1 day';
