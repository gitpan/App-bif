CREATE TABLE project_issues (
    id INTEGER NOT NULL PRIMARY KEY,
    issue_id INTEGER NOT NULL,
    project_id INTEGER NOT NULL,
    status_id INTEGER NOT NULL,
    update_id INTEGER NOT NULL,
    UNIQUE (issue_id,project_id),
    FOREIGN KEY(issue_id) REFERENCES issues(id) ON DELETE CASCADE,
    FOREIGN KEY(project_id,status_id) REFERENCES issue_status(project_id,id)
        ON DELETE CASCADE,
    FOREIGN KEY(update_id) REFERENCES updates(id) ON DELETE CASCADE
);

CREATE TRIGGER
    project_issues_bi_1
BEFORE INSERT ON
    project_issues
FOR EACH ROW WHEN
    EXISTS (
        SELECT
            1
        FROM
            project_issues
        WHERE
            id = NEW.id
    )
BEGIN

    SELECT debug(
        'TRIGGER project_issues_bi_1',
        NEW.id,
        NEW.issue_id,
        NEW.project_id,
        NEW.status_id,
        NEW.update_id
    );


    UPDATE
        project_issues
    SET
-- Set these or not? They are not supposed to change
--        issue_id = NEW.issue_id,
--        project_id = NEW.project_id,
        status_id = NEW.status_id,
        update_id = NEW.update_id
    WHERE
        id = NEW.id
    ;

    SELECT RAISE(IGNORE);
END;

/*
    This is to account for the lack of cascade deletes when a project
    is deleted.
*/
CREATE TRIGGER
    project_issues_ad_1
AFTER DELETE ON
    project_issues
FOR EACH ROW WHEN
    (
        SELECT
            COUNT(issue_id) = 0
        FROM
            project_issues
        WHERE
            issue_id = OLD.issue_id
    )
BEGIN
    SELECT debug(
        'TRIGGER project_issues_ad_1',
        OLD.issue_id,
        OLD.project_id,
        OLD.status_id,
        OLD.update_id
    );

    DELETE FROM
        issues
    WHERE
        id = OLD.issue_id
    ;
END;
