-- Инициализация Citus-кластера (выполнять на coordinator).
CREATE EXTENSION IF NOT EXISTS citus;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_dist_node
        WHERE nodename = 'citus-worker-01'
          AND nodeport = 5432
    ) THEN
        PERFORM master_add_node('citus-worker-01', 5432);
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_dist_node
        WHERE nodename = 'citus-worker-02'
          AND nodeport = 5432
    ) THEN
        PERFORM master_add_node('citus-worker-02', 5432);
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_dist_node
        WHERE nodename = 'citus-worker-03'
          AND nodeport = 5432
    ) THEN
        PERFORM master_add_node('citus-worker-03', 5432);
    END IF;
END $$;

SELECT nodeid, nodename, nodeport
FROM pg_dist_node
ORDER BY nodeid;
