CREATE TABLE IF NOT EXISTS dictionary.deposits
(
    book_id     INT            NOT NULL
        CONSTRAINT uq_deposits UNIQUE,
    deposit     NUMERIC(15, 2) NOT NULL,
    ch_staff_id INT            NOT NULL,
    ch_dt       TIMESTAMPTZ    NOT NULL
);