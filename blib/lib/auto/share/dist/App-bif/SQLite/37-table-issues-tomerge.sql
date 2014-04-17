CREATE TABLE issues_tomerge(
    issue_id INTEGER NOT NULL UNIQUE,
    title INTEGER DEFAULT 0,
    resolve INTEGER,
    FOREIGN KEY(issue_id) REFERENCES issues(id) ON DELETE CASCADE
);

CREATE TRIGGER
    bu_issues_tomerge_2
BEFORE UPDATE OF
    resolve
ON
    issues_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1
BEGIN

    SELECT debug(
        'TRIGGER bu_issues_tomerge_2',
        OLD.issue_id
    );

    UPDATE
        topics
    SET
        mtime = (
            SELECT
                updates.mtime
            FROM
                issue_updates
            INNER JOIN
                updates
            ON
                updates.id = issue_updates.update_id
            WHERE
                issue_updates.issue_id = OLD.issue_id
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
    bu_issues_tomerge_1
BEFORE UPDATE OF
    resolve
ON
    issues_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1 AND
    OLD.title != 0
BEGIN

    SELECT debug(
        'TRIGGER bu_issues_tomerge_1',
        OLD.issue_id
    );

    UPDATE
        issues
    SET
        title = (
            SELECT
                issue_updates.title
            FROM
                issue_updates
            INNER JOIN
                updates
            ON
                updates.id = issue_updates.update_id
            WHERE
                issue_updates.issue_id = OLD.issue_id AND
                issue_updates.title IS NOT NULL
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
