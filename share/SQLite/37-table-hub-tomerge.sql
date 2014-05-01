CREATE TABLE hub_tomerge(
    hub_id INTEGER NOT NULL UNIQUE,
    default_location_id INTEGER DEFAULT 0,
    resolve INTEGER,
    FOREIGN KEY(hub_id) REFERENCES hubs(id) ON DELETE CASCADE
);

CREATE TRIGGER
    bu_hub_tomerge_3
BEFORE UPDATE OF
    resolve
ON
    hub_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1
BEGIN

    SELECT debug(
        'TRIGGER bu_hub_tomerge_3',
        OLD.hub_id
    );

    UPDATE
        topics
    SET
        mtime = (
            SELECT
                updates.mtime
            FROM
                hub_updates
            INNER JOIN
                updates
            ON
                updates.id = hub_updates.update_id
            WHERE
                hub_updates.hub_id = OLD.hub_id
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
    bu_hub_tomerge_2
BEFORE UPDATE OF
    resolve
ON
    hub_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1 AND
    OLD.default_location_id != 0
BEGIN

    SELECT debug(
        'TRIGGER bu_hub_tomerge_2',
        OLD.hub_id
    );

    UPDATE
        hubs
    SET
        default_location_id = (
            SELECT
                hub_updates.default_location_id
            FROM
                hub_updates
            INNER JOIN
                updates
            ON
                updates.id = hub_updates.update_id
            WHERE
                hub_updates.hub_id = OLD.hub_id AND
                hub_updates.default_location_id IS NOT NULL
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
