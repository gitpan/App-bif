CREATE TABLE func_update_issue(
    change_id INTEGER NOT NULL,
    id INTEGER NOT NULL, -- This is issues.id not project_issues.id!
    project_id INTEGER NOT NULL,
    issue_status_id INTEGER,
    title VARCHAR
);

CREATE TRIGGER
    func_update_issue_bi_1
BEFORE INSERT ON
    func_update_issue
FOR EACH ROW BEGIN

    SELECT debug(
        'TRIGGER func_update_issue_bi_1',
        NEW.id,
        NEW.change_id,
        NEW.project_id,
        NEW.issue_status_id,
        NEW.title
    );

    INSERT INTO
        issue_deltas(
            change_id,
            issue_id,
            project_id,
            issue_status_id,
            title
        )
    VALUES(
        NEW.change_id,
        NEW.id,
        NEW.project_id,
        NEW.issue_status_id,
        NEW.title
    );

    SELECT RAISE(IGNORE);

END;
