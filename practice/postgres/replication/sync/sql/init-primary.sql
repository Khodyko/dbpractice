-- Объекты на primary: роль репликации, слот, таблица для pgbench.
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'repluser') THEN
    CREATE ROLE repluser WITH REPLICATION LOGIN PASSWORD 'replpass';
  END IF;
END $$;

SELECT pg_create_physical_replication_slot('standby1_slot', true, false)
WHERE NOT EXISTS (SELECT 1 FROM pg_replication_slots WHERE slot_name = 'standby1_slot');

CREATE TABLE IF NOT EXISTS bench_write (
    id         BIGSERIAL PRIMARY KEY,
    payload    TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
