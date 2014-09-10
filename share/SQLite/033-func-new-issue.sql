CREATE TABLE func_new_issue(
    update_id INTEGER NOT NULL,
    id INTEGER NOT NULL DEFAULT (nextval('topics')),
    topic_id INTEGER NOT NULL,
    status_id INTEGER NOT NULL,
    title VARCHAR(1024) NOT NULL DEFAULT ''
);

CREATE TRIGGER
    func_new_issue_bi_1
BEFORE INSERT ON
    func_new_issue
FOR EACH ROW
BEGIN

    SELECT debug(
        'TRIGGER func_new_issue_bi_1',
        NEW.id,
        NEW.topic_id,
        NEW.status_id,
        NEW.title,
        NEW.update_id
    );

    INSERT INTO issues(
        id
    )
    VALUES(
        NEW.topic_id
    );

    INSERT INTO
        issue_deltas(
            update_id,
            new,
            issue_id,
            project_id,
            status_id,
            title
        )
    SELECT
        NEW.update_id,
        1,
        NEW.topic_id,
        issue_status.project_id,
        NEW.status_id,
        NEW.title
    FROM
        issue_status
    WHERE
        issue_status.id = NEW.status_id
    ;

    /*
        This row would be inserted/updated by triggers on
        issues_tomerge[_status] anyway, but we do it here because the
        callers want to be able to define and know the project_issue_id
        in advance.
    */
    INSERT INTO
        project_issues(
            id,
            issue_id,
            project_id,
            status_id,
            update_id
        )
    SELECT
        NEW.id,
        NEW.topic_id,
        issue_status.project_id,
        NEW.status_id,
        NEW.update_id
    FROM
        issue_status
    WHERE
        issue_status.id = NEW.status_id
    ;

    SELECT RAISE(IGNORE);
END;
