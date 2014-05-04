CREATE TABLE func_new_issue(
    update_id INTEGER NOT NULL,
    id INTEGER NOT NULL DEFAULT (nextval('topics')),
    status_id INTEGER NOT NULL,
    title VARCHAR(1024) NOT NULL DEFAULT ''
);

CREATE TRIGGER
    bi_func_new_issue_1
BEFORE INSERT ON
    func_new_issue
FOR EACH ROW
BEGIN

    SELECT debug(
        'TRIGGER bi_func_new_issue_1',
        NEW.id,
        NEW.status_id,
        NEW.title,
        NEW.update_id
    );

    INSERT INTO
        topics(
            id,
            first_update_id,
            kind,
            ctime,
            ctimetz,
            mtime,
            mtimetz,
            lang,
            uuid
        )
    SELECT
        NEW.id,
        NEW.update_id,
        'issue',
        updates.mtime,
        updates.mtimetz,
        updates.mtime,
        updates.mtimetz,
        updates.lang,
        sha1_hex(
            'issue',
            updates.author,
            updates.email,
            updates.lang,
            updates.message,
            updates.mtime,
            updates.mtimetz,
            NEW.title,
            topics.uuid
        )
    FROM
        updates
    INNER JOIN
        topics
    ON
        topics.id = NEW.status_id
    WHERE
        updates.id = NEW.update_id
    ;

    INSERT INTO issues(
        id
    )
    VALUES(
        NEW.id
    );

    INSERT INTO
        issue_updates(
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
        NEW.id,
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
        NEW.id,
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
