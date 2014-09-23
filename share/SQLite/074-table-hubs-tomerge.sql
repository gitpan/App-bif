CREATE TABLE hubs_tomerge(
    hub_id INTEGER NOT NULL UNIQUE,
    name INTEGER DEFAULT 0,
    resolve INTEGER,
    FOREIGN KEY(hub_id) REFERENCES hubs(id) ON DELETE CASCADE
);

CREATE TRIGGER
    hubs_tomerge_bu_3
BEFORE UPDATE OF
    resolve
ON
    hubs_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1
BEGIN

    SELECT debug(
        OLD.hub_id
    );

    UPDATE
        topics
    SET
        mtime = (
            SELECT
                changes.mtime
            FROM
                hub_deltas
            INNER JOIN
                changes
            ON
                changes.id = hub_deltas.change_id
            WHERE
                hub_deltas.hub_id = OLD.hub_id
            ORDER BY
                changes.mtime DESC,
                changes.uuid
            LIMIT
                1
        )
    WHERE
        id = OLD.hub_id
    ;

    DELETE FROM
        hubs_tomerge
    WHERE
        hub_id = OLD.hub_id
    ;

    SELECT RAISE(IGNORE);

END;


CREATE TRIGGER
    hubs_tomerge_bu_1
BEFORE UPDATE OF
    resolve
ON
    hubs_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1 AND
    OLD.name != 0
BEGIN

    SELECT debug(
        OLD.hub_id
    );

    UPDATE
        hubs
    SET
        name = (
            SELECT
                hub_deltas.name
            FROM
                hub_deltas
            INNER JOIN
                changes
            ON
                changes.id = hub_deltas.change_id
            WHERE
                hub_deltas.hub_id = OLD.hub_id AND
                hub_deltas.name IS NOT NULL
            ORDER BY
                changes.mtime DESC,
                changes.uuid
            LIMIT
                1
        )
    WHERE
        id = OLD.hub_id
    ;

END;

