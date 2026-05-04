DROP TABLE IF EXISTS users_demo;
CREATE TABLE users_demo (
    id BIGSERIAL PRIMARY KEY,
    email TEXT NOT NULL
);

INSERT INTO users_demo (email)
SELECT 'User' || gs || '@Demo.Local'
FROM generate_series(1, 500000) gs;

CREATE INDEX idx_users_email ON users_demo (email);

EXPLAIN ANALYZE
SELECT * FROM users_demo
WHERE lower(email) = lower('User250000@Demo.Local');

CREATE INDEX idx_users_email_lower ON users_demo ((lower(email)));

EXPLAIN ANALYZE
SELECT * FROM users_demo
WHERE lower(email) = lower('User250000@Demo.Local');
