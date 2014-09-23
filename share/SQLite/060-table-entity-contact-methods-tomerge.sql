CREATE TABLE entity_contact_methods_tomerge(
    entity_contact_method_id INTEGER NOT NULL UNIQUE,
    method INTEGER DEFAULT 0,
    mvalue INTEGER DEFAULT 0,
    resolve INTEGER,
    FOREIGN KEY(entity_contact_method_id) REFERENCES entity_contact_methods(id)
        ON DELETE CASCADE
);

CREATE TRIGGER
    entity_contact_methods_tomerge_bu_3
BEFORE UPDATE OF
    resolve
ON
    entity_contact_methods_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1
BEGIN

    SELECT debug(
        OLD.entity_contact_method_id
    );

    UPDATE
        topics
    SET
        mtime = (
            SELECT
                changes.mtime
            FROM
                entity_contact_method_deltas
            INNER JOIN
                changes
            ON
                changes.id = entity_contact_method_deltas.change_id
            WHERE
                entity_contact_method_deltas.entity_contact_method_id =
                    OLD.entity_contact_method_id
            ORDER BY
                changes.mtime DESC,
                changes.uuid
            LIMIT
                1
        )
    WHERE
        id = OLD.entity_contact_method_id
    ;

    DELETE FROM
        entity_contact_methods_tomerge
    WHERE
        entity_contact_method_id = OLD.entity_contact_method_id
    ;

    SELECT RAISE(IGNORE);

END;

CREATE TRIGGER
    entity_contact_methods_tomerge_bu_2
BEFORE UPDATE OF
    resolve
ON
    entity_contact_methods_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1 AND
    OLD.method != 0
BEGIN

    SELECT debug(
        OLD.entity_contact_method_id
    );

    UPDATE
        entity_contact_methods
    SET
        method = (
            SELECT
                entity_contact_method_deltas.method
            FROM
                entity_contact_method_deltas
            INNER JOIN
                changes
            ON
                changes.id = entity_contact_method_deltas.change_id
            WHERE
                entity_contact_method_deltas.entity_contact_method_id =
                    OLD.entity_contact_method_id AND
                entity_contact_method_deltas.method IS NOT NULL
            ORDER BY
                changes.mtime DESC,
                changes.uuid
            LIMIT
                1
        )
    WHERE
        id = OLD.entity_contact_method_id
    ;

END;

CREATE TRIGGER
    entity_contact_methods_tomerge_bu_1
BEFORE UPDATE OF
    resolve
ON
    entity_contact_methods_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1 AND
    OLD.mvalue != 0
BEGIN

    SELECT debug(
        OLD.entity_contact_method_id
    );

    UPDATE
        entity_contact_methods
    SET
        mvalue = (
            SELECT
                entity_contact_method_deltas.mvalue
            FROM
                entity_contact_method_deltas
            INNER JOIN
                changes
            ON
                changes.id = entity_contact_method_deltas.change_id
            WHERE
                entity_contact_method_deltas.entity_contact_method_id =
                    OLD.entity_contact_method_id AND
                entity_contact_method_deltas.mvalue IS NOT NULL
            ORDER BY
                changes.mtime DESC,
                changes.uuid
            LIMIT
                1
        )
    WHERE
        id = OLD.entity_contact_method_id
    ;

END;

