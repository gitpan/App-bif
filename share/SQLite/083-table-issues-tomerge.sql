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
                changes.mtime
            FROM
                issue_deltas
            INNER JOIN
                changes
            ON
                changes.id = issue_deltas.change_id
            WHERE
                issue_deltas.issue_id = OLD.issue_id
            ORDER BY
                changes.mtime DESC,
                changes.uuid
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
                changes
            ON
                changes.id = issue_deltas.change_id
            WHERE
                issue_deltas.issue_id = OLD.issue_id AND
                issue_deltas.title IS NOT NULL
            ORDER BY
                changes.mtime DESC,
                changes.uuid
            LIMIT
                1
        )
    WHERE
        id = OLD.issue_id
    ;

END;
