CREATE TABLE identities_tomerge(
    identity_id INTEGER NOT NULL UNIQUE,
    shortname INTEGER DEFAULT 0,
    resolve INTEGER,
    FOREIGN KEY(identity_id) REFERENCES identities(id) ON DELETE CASCADE
);

CREATE TRIGGER
    identities_tomerge_bu_1
BEFORE UPDATE OF
    resolve
ON
    identities_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1 AND
    OLD.shortname != 0
BEGIN

    SELECT debug(
        NEW.identity_id,
        NEW.shortname
    );

    UPDATE
        identities
    SET
        shortname = (
            SELECT
                identity_deltas.shortname
            FROM
                identity_deltas
            INNER JOIN
                changes
            ON
                changes.id = identity_deltas.change_id
            WHERE
                identity_deltas.identity_id = OLD.identity_id AND
                identity_deltas.shortname IS NOT NULL
            ORDER BY
                changes.mtime DESC,
                changes.uuid
            LIMIT
                1
        )
    WHERE
        id = OLD.identity_id
    ;

END;


CREATE TRIGGER
    identities_tomerge_au_1
AFTER UPDATE OF
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
                changes.mtime
            FROM
                identity_deltas
            INNER JOIN
                changes
            ON
                changes.id = identity_deltas.change_id
            WHERE
                identity_deltas.identity_id = OLD.identity_id
            ORDER BY
                changes.mtime DESC,
                changes.uuid
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

