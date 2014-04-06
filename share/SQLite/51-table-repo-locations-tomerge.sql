CREATE TABLE repo_locations_tomerge(
    repo_location_id INTEGER NOT NULL UNIQUE,
    location INTEGER DEFAULT 0,
    resolve INTEGER,
    FOREIGN KEY(repo_location_id) REFERENCES repo_locations(id)
        ON DELETE CASCADE
);

CREATE TRIGGER
    bu_repo_locations_tomerge_4
BEFORE UPDATE OF
    resolve
ON
    repo_locations_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1
BEGIN

    SELECT debug(
        'TRIGGER bu_repo_locations_tomerge_4',
        OLD.repo_location_id
    );

    UPDATE
        topics
    SET
        mtime = (
            SELECT
                updates.mtime
            FROM
                repo_location_updates
            INNER JOIN
                updates
            ON
                updates.id = repo_location_updates.update_id
            WHERE
                repo_location_updates.repo_location_id =
                    OLD.repo_location_id
            ORDER BY
                updates.mtime DESC,
                updates.uuid
            LIMIT
                1
        )
    WHERE
        id = OLD.repo_location_id
    ;

    DELETE FROM
        repo_locations_tomerge
    WHERE
        repo_location_id = OLD.repo_location_id
    ;

    SELECT RAISE(IGNORE);

END;

CREATE TRIGGER
    bu_repo_locations_tomerge_1
BEFORE UPDATE OF
    resolve
ON
    repo_locations_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1 AND
    OLD.location != 0
BEGIN

    SELECT debug(
        'TRIGGER bu_repo_locations_tomerge_1',
        OLD.repo_location_id
    );


    UPDATE
        repo_locations
    SET
        location = (
            SELECT
                repo_location_updates.location
            FROM
                repo_location_updates
            INNER JOIN
                updates
            ON
                updates.id = repo_location_updates.update_id
            WHERE
                repo_location_updates.repo_location_id =
                    OLD.repo_location_id AND
                repo_location_updates.location IS NOT NULL
            ORDER BY
                updates.mtime DESC,
                updates.uuid
            LIMIT
                1
        )
    WHERE
        id = OLD.repo_location_id
    ;

END;

