CREATE OR REPLACE FUNCTION library.issueds_upd(_src JSONB, _ch_staff_id INT) RETURNS JSONB
    SECURITY DEFINER
    LANGUAGE plpgsql
AS
$$
DECLARE
    _issued_id   BIGINT;
    _books       JSONB;
    _user_id     INT;
    _return_date DATE;
    _is_returned BOOLEAN;
    _deposit     NUMERIC(15, 2);
    _ch_dt       TIMESTAMPTZ := now() AT TIME ZONE 'Europe/Moscow';
BEGIN
    SELECT coalesce(i.issued_id, nextval('library.issueds_sq')) AS issued_id,
           s.books,
           s.user_id,
           s.return_date,
           s.is_returned,
           s.deposit
    INTO _issued_id, _books, _user_id, _return_date, _is_returned, _deposit
    FROM jsonb_to_record(_src) AS s (issued_id BIGINT,
                                     books JSONB,
                                     user_id INT,
                                     return_date DATE,
                                     is_returned BOOLEAN,
                                     deposit NUMERIC(15, 2))
             LEFT JOIN library.issueds i ON i.issued_id = s.issued_id;

    CREATE TEMP TABLE tmp ON COMMIT DROP AS
    SELECT book_id FROM jsonb_to_recordset(_books) AS data (book_id INT);

    IF EXISTS (SELECT 1
               FROM tmp
                        LEFT JOIN library.books b ON tmp.book_id = b.book_id
               WHERE b.book_id IS NULL) THEN
        RETURN public.errmessage(_errcode := 'library.issueds_upd.not_possible',
                                 _msg := 'Выдача данных книг невозможна',
                                 _detail := concat('book_id = ', (SELECT array_agg(tmp.book_id)
                                                                  FROM tmp
                                                                           LEFT JOIN library.books b ON tmp.book_id = b.book_id
                                                                  WHERE b.book_id IS NULL)));
    END IF;

    SELECT COALESCE(SUM(b.deposit), 0)
    FROM tmp
             JOIN library.books b ON tmp.book_id = b.book_id
    INTO _deposit;

    UPDATE library.books
    SET is_available = FALSE
    WHERE book_id IN (SELECT book_id FROM tmp);

    WITH cte AS (
        INSERT INTO library.issueds AS ec (issued_id, user_id, return_date, is_returned, deposit, ch_staff_id, ch_dt)
            VALUES (_issued_id, _user_id, _return_date, _is_returned, _deposit, _ch_staff_id, _ch_dt)
            ON CONFLICT (issued_id) DO UPDATE
                SET user_id = excluded.user_id,
                    return_date = excluded.return_date,
                    is_returned = excluded.is_returned,
                    deposit = excluded.deposit,
                    ch_staff_id = excluded.ch_staff_id,
                    ch_dt = excluded.ch_dt
            RETURNING ec.*)
    INSERT
    INTO history.issuedschanges (issued_id, user_id, return_date, is_returned, deposit, ch_staff_id, ch_dt)
    SELECT issued_id, user_id, return_date, is_returned, deposit, ch_staff_id, ch_dt
    FROM cte ic;

    INSERT INTO library.issuedsbooks (issued_id, book_id, dt)
    SELECT _issued_id, (elem ->> 'book_id')::INT, _ch_dt
    FROM jsonb_array_elements(_books) AS elem
    ON CONFLICT (issued_id,book_id) DO UPDATE
        SET book_id = excluded.book_id,
            dt      = excluded.dt;

    RETURN JSONB_BUILD_OBJECT('data', NULL);
END
$$;