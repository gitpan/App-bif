CREATE TABLE repo_tomerge(
    repo_id INTEGER NOT NULL UNIQUE,
    default_location_id INTEGER DEFAULT 0,
    resolve INTEGER,
    FOREIGN KEY(repo_id) REFERENCES repos(id) ON DELETE CASCADE
);

CREATE TRIGGER
    bu_repo_tomerge_3
BEFORE UPDATE OF
    resolve
ON
    repo_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1
BEGIN

    SELECT debug(
        'TRIGGER bu_repo_tomerge_3',
        OLD.repo_id
    );

    UPDATE
        topics
    SET
        mtime = (
            SELECT
                updates.mtime
            FROM
                repo_updates
            INNER JOIN
                updates
            ON
                updates.id = repo_updates.update_id
            WHERE
                repo_updates.repo_id = OLD.repo_id
            ORDER BY
                updates.mtime DESC,
                updates.uuid
            LIMIT
                1
        )
    WHERE
        id = OLD.repo_id
    ;

    DELETE FROM
        repo_tomerge
    WHERE
        repo_id = OLD.repo_id
    ;

    SELECT RAISE(IGNORE);

END;

CREATE TRIGGER
    bu_repo_tomerge_2
BEFORE UPDATE OF
    resolve
ON
    repo_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1 AND
    OLD.default_location_id != 0
BEGIN

    SELECT debug(
        'TRIGGER bu_repo_tomerge_2',
        OLD.repo_id
    );

    UPDATE
        repos
    SET
        default_location_id = (
            SELECT
                repo_updates.default_location_id
            FROM
                repo_updates
            INNER JOIN
                updates
            ON
                updates.id = repo_updates.update_id
            WHERE
                repo_updates.repo_id = OLD.repo_id AND
                repo_updates.default_location_id IS NOT NULL
            ORDER BY
                updates.mtime DESC,
                updates.uuid
            LIMIT
                1
        )
    WHERE
        id = OLD.repo_id
    ;

END;

