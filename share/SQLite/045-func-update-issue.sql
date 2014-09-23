CREATE TABLE func_change_issue(
    change_id INTEGER NOT NULL,
    id INTEGER NOT NULL, -- This is issues.id not project_issues.id!
    project_id INTEGER NOT NULL,
    status_id INTEGER,
    title VARCHAR
);

CREATE TRIGGER
    func_change_issue_bi_1
BEFORE INSERT ON
    func_change_issue
FOR EACH ROW BEGIN

    SELECT debug(
        'TRIGGER func_change_issue_bi_1',
        NEW.id,
        NEW.change_id,
        NEW.project_id,
        NEW.status_id,
        NEW.title
    );

    INSERT INTO
        issue_deltas(
            change_id,
            issue_id,
            project_id,
            status_id,
            title
        )
    VALUES(
        NEW.change_id,
        NEW.id,
        NEW.project_id,
        NEW.status_id,
        NEW.title
    );

    SELECT RAISE(IGNORE);

END;
