CREATE TABLE issues_tomerge(
    issue_id INTEGER NOT NULL UNIQUE,
    title INTEGER DEFAULT 0,
    resolve INTEGER,
    FOREIGN KEY(issue_id) REFERENCES issues(id) ON DELETE CASCADE
);

CREATE TRIGGER
    issues_tomerge_bu_2
BEFORE UPDATE OF
    resolve
ON
    issues_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1
BEGIN

    SELECT debug(
        'TRIGGER issues_tomerge_bu_2',
        OLD.issue_id
    );

    UPDATE
        topics
    SET
        mtime = (
            SELECT
                updates.mtime
            FROM
                issue_deltas
            INNER JOIN
                updates
            ON
                updates.id = issue_deltas.update_id
            WHERE
                issue_deltas.issue_id = OLD.issue_id
            ORDER BY
                updates.mtime DESC,
                updates.uuid
            LIMIT
                1
        )
    WHERE
        id = OLD.issue_id
    ;

    DELETE FROM
        issues_tomerge
    WHERE
        issue_id = OLD.issue_id
    ;

    SELECT RAISE(IGNORE);
END;

CREATE TRIGGER
    issues_tomerge_bu_1
BEFORE UPDATE OF
    resolve
ON
    issues_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1 AND
    OLD.title != 0
BEGIN

    SELECT debug(
        'TRIGGER issues_tomerge_bu_1',
        OLD.issue_id
    );

    UPDATE
        issues
    SET
        title = (
            SELECT
                issue_deltas.title
            FROM
                issue_deltas
            INNER JOIN
                updates
            ON
                updates.id = issue_deltas.update_id
            WHERE
                issue_deltas.issue_id = OLD.issue_id AND
                issue_deltas.title IS NOT NULL
            ORDER BY
                updates.mtime DESC,
                updates.uuid
            LIMIT
                1
        )
    WHERE
        id = OLD.issue_id
    ;

END;
