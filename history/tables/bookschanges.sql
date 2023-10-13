CREATE TABLE IF NOT EXISTS history.books
(
    log_id BIGINT NOT NULL,
    book_id INT NOT NULL
        CONSTRAINT pk_book PRIMARY KEY,
    genre_id INT NOT NULL,
    cell_id INT NOT NULL,
    name VARCHAR(128) NOT NULL,
    author VARCHAR(128) NOT NULL,
    description VARCHAR(320) NOT NULL,
    is_available BOOLEAN NOT NULL
);