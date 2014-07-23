CREATE TABLE func_new_entity(
    update_id INTEGER NOT NULL,
    id INTEGER NOT NULL DEFAULT (nextval('topics')),
    kind VARCHAR NOT NULL,
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
        NEW.kind,
        NEW.name
    );

    INSERT INTO
        topics(
            id,
            first_update_id,
            kind,
            ctime,
            ctimetz,
            mtime,
            mtimetz,
            lang,
            uuid
        )
    SELECT
        NEW.id,
        NEW.update_id,
        NEW.kind,
        updates.mtime,
        updates.mtimetz,
        updates.mtime,
        updates.mtimetz,
        updates.lang,
        sha1_hex(
            NEW.kind,
            updates.author,
            updates.email,
            updates.lang,
            updates.message,
            updates.mtime,
            updates.mtimetz,
            NEW.name
        )
    FROM
        updates
    WHERE
        updates.id = NEW.update_id
    ;

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
