-- С pg-primary: подключение к pg-subscriber, таблица и subscription events_sub.
\c postgresql://demo:demo@pg-subscriber:5432/repl_demo

CREATE TABLE events (
    id          BIGINT PRIMARY KEY,
    event_type  TEXT NOT NULL,
    payload     TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE SUBSCRIPTION events_sub
    CONNECTION 'host=pg-primary port=5432 dbname=repl_demo user=repluser password=replpass'
    PUBLICATION events_only
    WITH (copy_data = true);
