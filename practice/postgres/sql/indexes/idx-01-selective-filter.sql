DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INT NOT NULL,
    status TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL,
    email TEXT NOT NULL,
    amount NUMERIC(12, 2) NOT NULL
);

INSERT INTO orders (tenant_id, status, created_at, email, amount)
SELECT
    (random() * 1000)::INT,
    CASE WHEN random() < 0.9 THEN 'ACTIVE' ELSE 'ARCHIVED' END,
    now() - (random() * interval '365 days'),
    'user' || gs || '@demo.local',
    (random() * 10000)::NUMERIC(12, 2)
FROM generate_series(1, 500000) gs;

EXPLAIN ANALYZE
SELECT * FROM orders WHERE email = 'user250000@demo.local';

CREATE INDEX idx_orders_email ON orders (email);

EXPLAIN ANALYZE
SELECT * FROM orders WHERE email = 'user250000@demo.local';
