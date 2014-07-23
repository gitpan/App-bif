CREATE TABLE func_new_entity_contact_method(
    update_id INTEGER NOT NULL,
    id INTEGER NOT NULL DEFAULT (nextval('topics')),
    entity_id INTEGER NOT NULL,
    method VARCHAR NOT NULL,
    mvalue VARCHAR NOT NULL
);


CREATE TRIGGER
    func_new_entity_contact_method_bi_1
BEFORE INSERT ON
    func_new_entity_contact_method
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.update_id,
        NEW.id,
        NEW.entity_id,
        NEW.method,
        NEW.mvalue
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
        'entity_contact_method',
        updates.mtime,
        updates.mtimetz,
        updates.mtime,
        updates.mtimetz,
        updates.lang,
        sha1_hex(
            'entity_contact_method',
            updates.author,
            updates.email,
            updates.lang,
            updates.message,
            updates.mtime,
            updates.mtimetz,
            NEW.method,
            NEW.mvalue,
            e.uuid
        )
    FROM
        updates
    INNER JOIN
        topics e
    ON
        e.id = NEW.entity_id
    WHERE
        updates.id = NEW.update_id
    ;

    INSERT INTO entity_contact_methods(
        id,
        entity_id,
        method,
        mvalue
    )
    VALUES(
        NEW.id,
        NEW.entity_id,
        NEW.method,
        NEW.mvalue
    );

    INSERT INTO
        entity_contact_method_deltas(
            update_id,
            entity_contact_method_id,
            new,
            method,
            mvalue
        )
    VALUES(
        NEW.update_id,
        NEW.id,
        1,
        NEW.method,
        NEW.mvalue
    );

    SELECT RAISE(IGNORE);
END;
