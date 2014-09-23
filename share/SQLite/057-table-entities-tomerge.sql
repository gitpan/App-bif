CREATE TABLE entities_tomerge(
    entity_id INTEGER NOT NULL UNIQUE,
    contact_id INTEGER DEFAULT 0,
    default_contact_method_id INTEGER DEFAULT 0,
    name INTEGER DEFAULT 0,
    resolve INTEGER,
    FOREIGN KEY(entity_id) REFERENCES entities(id) ON DELETE CASCADE
);

CREATE TRIGGER
    entities_tomerge_bu_4
BEFORE UPDATE OF
    resolve
ON
    entities_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1
BEGIN

    SELECT debug(
        OLD.entity_id
    );

    UPDATE
        topics
    SET
        mtime = (
            SELECT
                changes.mtime
            FROM
                entity_deltas
            INNER JOIN
                changes
            ON
                changes.id = entity_deltas.change_id
            WHERE
                entity_deltas.entity_id = OLD.entity_id
            ORDER BY
                changes.mtime DESC,
                changes.uuid
            LIMIT
                1
        )
    WHERE
        id = OLD.entity_id
    ;

    DELETE FROM
        entities_tomerge
    WHERE
        entity_id = OLD.entity_id
    ;

    SELECT RAISE(IGNORE);

END;

CREATE TRIGGER
    entities_tomerge_bu_3
BEFORE UPDATE OF
    resolve
ON
    entities_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1 AND
    OLD.contact_id != 0
BEGIN

    SELECT debug(
        OLD.entity_id
    );

    UPDATE
        entities
    SET
        contact_id = (
            SELECT
                entity_deltas.contact_id
            FROM
                entity_deltas
            INNER JOIN
                changes
            ON
                changes.id = entity_deltas.change_id
            WHERE
                entity_deltas.entity_id = OLD.entity_id AND
                entity_deltas.contact_id IS NOT NULL
            ORDER BY
                changes.mtime DESC,
                changes.uuid
            LIMIT
                1
        )
    WHERE
        id = OLD.entity_id
    ;

END;

CREATE TRIGGER
    entities_tomerge_bu_2
BEFORE UPDATE OF
    resolve
ON
    entities_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1 AND
    OLD.default_contact_method_id != 0
BEGIN

    SELECT debug(
        OLD.entity_id
    );

    UPDATE
        entities
    SET
        default_contact_method_id = (
            SELECT
                entity_deltas.default_contact_method_id
            FROM
                entity_deltas
            INNER JOIN
                changes
            ON
                changes.id = entity_deltas.change_id
            WHERE
                entity_deltas.entity_id = OLD.entity_id AND
                entity_deltas.default_contact_method_id IS NOT NULL
            ORDER BY
                changes.mtime DESC,
                changes.uuid
            LIMIT
                1
        )
    WHERE
        id = OLD.entity_id
    ;

END;


CREATE TRIGGER
    entities_tomerge_bu_1
BEFORE UPDATE OF
    resolve
ON
    entities_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1 AND
    OLD.name != 0
BEGIN

    SELECT debug(
        OLD.entity_id
    );

    UPDATE
        entities
    SET
        name = (
            SELECT
                entity_deltas.name
            FROM
                entity_deltas
            INNER JOIN
                changes
            ON
                changes.id = entity_deltas.change_id
            WHERE
                entity_deltas.entity_id = OLD.entity_id AND
                entity_deltas.name IS NOT NULL
            ORDER BY
                changes.mtime DESC,
                changes.uuid
            LIMIT
                1
        )
    WHERE
        id = OLD.entity_id
    ;

END;

