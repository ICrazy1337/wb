CREATE TABLE IF NOT EXISTS library.places
(
    place_id SMALLSERIAL NOT NULL
        CONSTRAINT pk_place_id PRIMARY KEY,
    shelf_id SMALLINT NOT NULL
);