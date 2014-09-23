CREATE TABLE hub_repos_tomerge(
    hub_repo_id INTEGER NOT NULL UNIQUE,
    location INTEGER DEFAULT 0,
    resolve INTEGER,
    FOREIGN KEY(hub_repo_id) REFERENCES hub_repos(id)
        ON DELETE CASCADE
);

CREATE TRIGGER
    hub_repos_tomerge_bu_4
BEFORE UPDATE OF
    resolve
ON
    hub_repos_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1
BEGIN

    SELECT debug(
        'TRIGGER hub_repos_tomerge_bu_4',
        OLD.hub_repo_id
    );

    UPDATE
        topics
    SET
        mtime = (
            SELECT
                changes.mtime
            FROM
                hub_repo_deltas
            INNER JOIN
                changes
            ON
                changes.id = hub_repo_deltas.change_id
            WHERE
                hub_repo_deltas.hub_repo_id =
                    OLD.hub_repo_id
            ORDER BY
                changes.mtime DESC,
                changes.uuid
            LIMIT
                1
        )
    WHERE
        id = OLD.hub_repo_id
    ;

    DELETE FROM
        hub_repos_tomerge
    WHERE
        hub_repo_id = OLD.hub_repo_id
    ;

    SELECT RAISE(IGNORE);

END;

CREATE TRIGGER
    hub_repos_tomerge_bu_1
BEFORE UPDATE OF
    resolve
ON
    hub_repos_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1 AND
    OLD.location != 0
BEGIN

    SELECT debug(
        'TRIGGER hub_repos_tomerge_bu_1',
        OLD.hub_repo_id
    );


    UPDATE
        hub_repos
    SET
        location = (
            SELECT
                hub_repo_deltas.location
            FROM
                hub_repo_deltas
            INNER JOIN
                changes
            ON
                changes.id = hub_repo_deltas.change_id
            WHERE
                hub_repo_deltas.hub_repo_id =
                    OLD.hub_repo_id AND
                hub_repo_deltas.location IS NOT NULL
            ORDER BY
                changes.mtime DESC,
                changes.uuid
            LIMIT
                1
        )
    WHERE
        id = OLD.hub_repo_id
    ;

END;

