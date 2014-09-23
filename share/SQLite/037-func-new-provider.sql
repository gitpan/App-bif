CREATE TABLE func_new_provider(
    change_id INTEGER NOT NULL,
    id INTEGER NOT NULL DEFAULT (nextval('topics'))
);


CREATE TRIGGER
    func_new_provider_bi_1
BEFORE INSERT ON
    func_new_provider
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.change_id,
        NEW.id
    );

    INSERT INTO providers(
        id
    )
    VALUES(
        NEW.id
    );

    INSERT INTO
        provider_deltas(
            change_id,
            provider_id,
            new
        )
    VALUES(
        NEW.change_id,
        NEW.id,
        1
    );

    SELECT RAISE(IGNORE);
END;
