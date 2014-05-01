CREATE TABLE hub_locations_tomerge(
    hub_location_id INTEGER NOT NULL UNIQUE,
    location INTEGER DEFAULT 0,
    resolve INTEGER,
    FOREIGN KEY(hub_location_id) REFERENCES hub_locations(id)
        ON DELETE CASCADE
);

CREATE TRIGGER
    bu_hub_locations_tomerge_4
BEFORE UPDATE OF
    resolve
ON
    hub_locations_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1
BEGIN

    SELECT debug(
        'TRIGGER bu_hub_locations_tomerge_4',
        OLD.hub_location_id
    );

    UPDATE
        topics
    SET
        mtime = (
            SELECT
                updates.mtime
            FROM
                hub_location_updates
            INNER JOIN
                updates
            ON
                updates.id = hub_location_updates.update_id
            WHERE
                hub_location_updates.hub_location_id =
                    OLD.hub_location_id
            ORDER BY
                updates.mtime DESC,
                updates.uuid
            LIMIT
                1
        )
    WHERE
        id = OLD.hub_location_id
    ;

    DELETE FROM
        hub_locations_tomerge
    WHERE
        hub_location_id = OLD.hub_location_id
    ;

    SELECT RAISE(IGNORE);

END;

CREATE TRIGGER
    bu_hub_locations_tomerge_1
BEFORE UPDATE OF
    resolve
ON
    hub_locations_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1 AND
    OLD.location != 0
BEGIN

    SELECT debug(
        'TRIGGER bu_hub_locations_tomerge_1',
        OLD.hub_location_id
    );


    UPDATE
        hub_locations
    SET
        location = (
            SELECT
                hub_location_updates.location
            FROM
                hub_location_updates
            INNER JOIN
                updates
            ON
                updates.id = hub_location_updates.update_id
            WHERE
                hub_location_updates.hub_location_id =
                    OLD.hub_location_id AND
                hub_location_updates.location IS NOT NULL
            ORDER BY
                updates.mtime DESC,
                updates.uuid
            LIMIT
                1
        )
    WHERE
        id = OLD.hub_location_id
    ;

END;
