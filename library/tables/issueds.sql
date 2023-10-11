CREATE TABLE IF NOT EXISTS library.issueds
(
    issued_id INT NOT NULL,
    user_id INT NOT NULL,
    return_id DATE NOT NULL,
    ch_staff_id INT NOT NULL,
    ch_dt TIMESTAMPTZ NOT NULL,
    CONSTRAINT pk_issued PRIMARY KEY (issued_id, user_id)
);