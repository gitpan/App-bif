CREATE TABLE project_issues_tomerge(
    issue_id INTEGER NOT NULL,
    project_id INTEGER NOT NULL,
    resolve INTEGER,
    UNIQUE (issue_id, project_id),
    FOREIGN KEY(issue_id) REFERENCES issues(id) ON DELETE CASCADE,
    FOREIGN KEY(project_id) REFERENCES projects(id) ON DELETE CASCADE
);

CREATE TRIGGER
    project_issues_tomerge_bu_1
BEFORE UPDATE OF
    resolve
ON
    project_issues_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1
BEGIN

    SELECT debug(
        'TRIGGER project_issues_tomerge_bu_1',
        OLD.issue_id,
        OLD.project_id
    );

    INSERT INTO
        project_issues(
            id,
            issue_id,
            project_id,
            status_id,
            update_id
        )
    SELECT
        COALESCE(project_issues.id, nextval('topics')),
        OLD.issue_id,
        OLD.project_id,
        issue_deltas.status_id,
        updates.id
    FROM
        issue_deltas
    INNER JOIN
        updates
    ON
        updates.id = issue_deltas.update_id
    LEFT JOIN
        project_issues
    ON
        project_issues.issue_id = OLD.issue_id AND
        project_issues.project_id = OLD.project_id
    WHERE
        issue_deltas.issue_id = OLD.issue_id AND
        issue_deltas.project_id = OLD.project_id AND
        issue_deltas.status_id IS NOT NULL
    ORDER BY
        updates.mtime DESC,
        updates.uuid
    LIMIT
        1
    ;

    DELETE FROM
        project_issues_tomerge
    WHERE
        issue_id = OLD.issue_id AND project_id = OLD.project_id
    ;

    SELECT RAISE(IGNORE);

END;
