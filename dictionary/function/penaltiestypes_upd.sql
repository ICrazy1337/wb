CREATE OR REPLACE FUNCTION dictionary.penaltiestypes_upd(_src JSONB) RETURNS JSONB
    SECURITY DEFINER
    LANGUAGE plpgsql
AS
$$
DECLARE
    _type_id SMALLINT;
    _name VARCHAR(64);
    _amount NUMERIC(15, 2);
BEGIN
    SELECT type_id, name, amount
    INTO _type_id, _name, _amount
    FROM jsonb_to_record(_src) AS s (type_id SMALLINT,
                                     name VARCHAR(64),
                                     amount NUMERIC(15, 2));

    INSERT INTO dictionary.penaltiestypes AS ec (type_id, name, amount)
    SELECT _type_id, _name, _amount
    ON CONFLICT (type_id) DO UPDATE
        SET name     = excluded.name,
            amount      = excluded.amount;

    RETURN JSONB_BUILD_OBJECT('data', NULL);
END
$$;