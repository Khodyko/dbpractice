-- Primary: роль репликации, таблица, publication (как в типовой схеме master → publication).
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'repluser') THEN
    CREATE ROLE repluser WITH REPLICATION LOGIN PASSWORD 'replpass';
  END IF;
END $$;

GRANT CONNECT ON DATABASE repl_demo TO repluser;
GRANT USAGE ON SCHEMA public TO repluser;

DROP TABLE IF EXISTS events CASCADE;

CREATE TABLE events (
    id BIGINT PRIMARY KEY,
    event_type TEXT NOT NULL,
    payload TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

GRANT SELECT ON events TO repluser;

CREATE PUBLICATION events_only FOR TABLE events;
