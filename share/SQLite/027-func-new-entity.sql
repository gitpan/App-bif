CREATE TABLE func_new_entity(
    update_id INTEGER NOT NULL,
    id INTEGER NOT NULL,
    name VARCHAR NOT NULL
);


CREATE TRIGGER
    func_new_entity_bi_1
BEFORE INSERT ON
    func_new_entity
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.update_id,
        NEW.id,
        NEW.name
    );

    INSERT INTO entities(
        id,
        name
    )
    VALUES(
        NEW.id,
        NEW.name
    );

    INSERT INTO
        entity_deltas(
            update_id,
            entity_id,
            new,
            name
        )
    VALUES(
        NEW.update_id,
        NEW.id,
        1,
        NEW.name
    );

    SELECT RAISE(IGNORE);
END;
