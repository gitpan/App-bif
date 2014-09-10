CREATE TABLE identities_tomerge(
    identity_id INTEGER NOT NULL UNIQUE,
    contact_id INTEGER DEFAULT 0,
    default_contact_method_id INTEGER DEFAULT 0,
    name INTEGER DEFAULT 0,
    resolve INTEGER,
    FOREIGN KEY(identity_id) REFERENCES identities(id) ON DELETE CASCADE
);

CREATE TRIGGER
    identities_tomerge_bu_4
BEFORE UPDATE OF
    resolve
ON
    identities_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1
BEGIN

    SELECT debug(
        OLD.identity_id
    );

    UPDATE
        topics
    SET
        mtime = (
            SELECT
                updates.mtime
            FROM
                identity_deltas
            INNER JOIN
                updates
            ON
                updates.id = identity_deltas.update_id
            WHERE
                identity_deltas.identity_id = OLD.identity_id
            ORDER BY
                updates.mtime DESC,
                updates.uuid
            LIMIT
                1
        )
    WHERE
        id = OLD.identity_id
    ;

    DELETE FROM
        identities_tomerge
    WHERE
        identity_id = OLD.identity_id
    ;

    SELECT RAISE(IGNORE);

END;

CREATE TRIGGER
    identities_tomerge_bu_3
BEFORE UPDATE OF
    resolve
ON
    identities_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1 AND
    OLD.contact_id != 0
BEGIN

    SELECT debug(
        OLD.identity_id
    );

    UPDATE
        identities
    SET
        contact_id = (
            SELECT
                identity_deltas.contact_id
            FROM
                identity_deltas
            INNER JOIN
                updates
            ON
                updates.id = identity_deltas.update_id
            WHERE
                identity_deltas.identity_id = OLD.identity_id AND
                identity_deltas.contact_id IS NOT NULL
            ORDER BY
                updates.mtime DESC,
                updates.uuid
            LIMIT
                1
        )
    WHERE
        id = OLD.identity_id
    ;

END;

CREATE TRIGGER
    identities_tomerge_bu_2
BEFORE UPDATE OF
    resolve
ON
    identities_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1 AND
    OLD.default_contact_method_id != 0
BEGIN

    SELECT debug(
        OLD.identity_id
    );

    UPDATE
        identities
    SET
        default_contact_method_id = (
            SELECT
                identity_deltas.default_contact_method_id
            FROM
                identity_deltas
            INNER JOIN
                updates
            ON
                updates.id = identity_deltas.update_id
            WHERE
                identity_deltas.identity_id = OLD.identity_id AND
                identity_deltas.default_contact_method_id IS NOT NULL
            ORDER BY
                updates.mtime DESC,
                updates.uuid
            LIMIT
                1
        )
    WHERE
        id = OLD.identity_id
    ;

END;


CREATE TRIGGER
    identities_tomerge_bu_1
BEFORE UPDATE OF
    resolve
ON
    identities_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1 AND
    OLD.name != 0
BEGIN

    SELECT debug(
        OLD.identity_id
    );

    UPDATE
        identities
    SET
        name = (
            SELECT
                identity_deltas.name
            FROM
                identity_deltas
            INNER JOIN
                updates
            ON
                updates.id = identity_deltas.update_id
            WHERE
                identity_deltas.identity_id = OLD.identity_id AND
                identity_deltas.name IS NOT NULL
            ORDER BY
                updates.mtime DESC,
                updates.uuid
            LIMIT
                1
        )
    WHERE
        id = OLD.identity_id
    ;

END;
