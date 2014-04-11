CREATE TABLE func_import_issue_update(
    issue_uuid VARCHAR(40),
    project_uuid VARCHAR(40),
    issue_status_uuid VARCHAR(40),
    title VARCHAR(1024)
);


CREATE TRIGGER
    bi_func_import_issue_update_1
BEFORE INSERT ON
    func_import_issue_update
FOR EACH ROW
BEGIN

    SELECT debug(
        'TRIGGER bi_func_import_issue_update_1',
        NEW.issue_status_uuid,
        NEW.title
    );

    INSERT INTO
        func_update_issue(
            id,
            project_id,
            status_id,
            title
        )
    SELECT
        issues.id,
        projects.id,
        issue_status.id,
        NEW.title
    FROM
        (SELECT 1)
    LEFT JOIN
        topics AS issues
    ON
        issues.uuid = NEW.issue_uuid
    LEFT JOIN
        topics AS projects
    ON
        projects.uuid = NEW.project_uuid
    LEFT JOIN
        topics AS issue_status
    ON
        issue_status.uuid = NEW.issue_status_uuid
    ;

    SELECT RAISE(IGNORE);
END;