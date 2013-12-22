CREATE TABLE project_issues_mergers(
    issue_id integer NOT NULL,
    project_id integer NOT NULL,
    resolve integer,
    UNIQUE (issue_id, project_id),
    FOREIGN KEY(issue_id) REFERENCES issues(id) ON DELETE CASCADE,
    FOREIGN KEY(project_id) REFERENCES projects(id) ON DELETE CASCADE
);

CREATE TRIGGER
    bu_project_issues_mergers_1
BEFORE UPDATE OF
    resolve
ON
    project_issues_mergers
FOR EACH ROW WHEN
    NEW.resolve = 1
BEGIN

    SELECT debug(
        'TRIGGER bu_project_issue_mergers_1',
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
        issue_updates.status_id,
        updates.id
    FROM
        issue_updates
    INNER JOIN
        updates
    ON
        updates.id = issue_updates.update_id
    LEFT JOIN
        project_issues
    ON
        project_issues.issue_id = OLD.issue_id AND
        project_issues.project_id = OLD.project_id
    WHERE
        issue_updates.issue_id = OLD.issue_id AND
        issue_updates.project_id = OLD.project_id AND
        issue_updates.status_id IS NOT NULL
    ORDER BY
        updates.mtime DESC,
        updates.uuid
    LIMIT
        1
    ;

    DELETE FROM
        project_issues_mergers
    WHERE
        issue_id = OLD.issue_id AND project_id = OLD.project_id
    ;

    SELECT RAISE(IGNORE);

END;
