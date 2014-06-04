CREATE TABLE hub_tomerge(
    hub_id INTEGER NOT NULL UNIQUE,
    name INTEGER DEFAULT 0,
    default_location_id INTEGER DEFAULT 0,
    resolve INTEGER,
    FOREIGN KEY(hub_id) REFERENCES hubs(id) ON DELETE CASCADE
);

CREATE TRIGGER
    hub_tomerge_bu_3
BEFORE UPDATE OF
    resolve
ON
    hub_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1
BEGIN

    SELECT debug(
        'TRIGGER hub_tomerge_bu_3',
        OLD.hub_id
    );

    UPDATE
        topics
    SET
        mtime = (
            SELECT
                updates.mtime
            FROM
                hub_deltas
            INNER JOIN
                updates
            ON
                updates.id = hub_deltas.update_id
            WHERE
                hub_deltas.hub_id = OLD.hub_id
            ORDER BY
                updates.mtime DESC,
                updates.uuid
            LIMIT
                1
        )
    WHERE
        id = OLD.hub_id
    ;

    DELETE FROM
        hub_tomerge
    WHERE
        hub_id = OLD.hub_id
    ;

    SELECT RAISE(IGNORE);

END;

CREATE TRIGGER
    hub_tomerge_bu_2
BEFORE UPDATE OF
    resolve
ON
    hub_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1 AND
    OLD.default_location_id != 0
BEGIN

    SELECT debug(
        'TRIGGER hub_tomerge_bu_2',
        OLD.hub_id
    );

    UPDATE
        hubs
    SET
        default_location_id = (
            SELECT
                hub_deltas.default_location_id
            FROM
                hub_deltas
            INNER JOIN
                updates
            ON
                updates.id = hub_deltas.update_id
            WHERE
                hub_deltas.hub_id = OLD.hub_id AND
                hub_deltas.default_location_id IS NOT NULL
            ORDER BY
                updates.mtime DESC,
                updates.uuid
            LIMIT
                1
        )
    WHERE
        id = OLD.hub_id
    ;

END;

CREATE TRIGGER
    hub_tomerge_bu_1
BEFORE UPDATE OF
    resolve
ON
    hub_tomerge
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
                updates
            ON
                updates.id = hub_deltas.update_id
            WHERE
                hub_deltas.hub_id = OLD.hub_id AND
                hub_deltas.name IS NOT NULL
            ORDER BY
                updates.mtime DESC,
                updates.uuid
            LIMIT
                1
        )
    WHERE
        id = OLD.hub_id
    ;

END;

