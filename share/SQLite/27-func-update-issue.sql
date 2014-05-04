CREATE TABLE func_update_issue(
    update_id INTEGER NOT NULL,
    id INTEGER NOT NULL, -- This is issues.id not project_issues.id!
    project_id INTEGER NOT NULL,
    status_id INTEGER,
    title VARCHAR
);

CREATE TRIGGER
    bi_func_update_issue_1
BEFORE INSERT ON
    func_update_issue
FOR EACH ROW BEGIN

    SELECT debug(
        'TRIGGER bi_func_update_issue_1',
        NEW.id,
        NEW.update_id,
        NEW.project_id,
        NEW.status_id,
        NEW.title
    );

    INSERT INTO
        issue_updates(
            update_id,
            issue_id,
            project_id,
            status_id,
            title
        )
    VALUES(
        NEW.update_id,
        NEW.id,
        NEW.project_id,
        NEW.status_id,
        NEW.title
    );

    SELECT RAISE(IGNORE);

END;
