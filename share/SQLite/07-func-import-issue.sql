CREATE TABLE func_import_issue(
    update_uuid VARCHAR(40) NOT NULL,
    issue_status_uuid VARCHAR(40),
    title VARCHAR(1024)
);


CREATE TRIGGER
    bi_func_import_issue_1
BEFORE INSERT ON
    func_import_issue
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.update_uuid,
        NEW.issue_status_uuid,
        NEW.title
    );

    INSERT INTO
        func_new_issue(
            update_id,
            status_id,
            title
        )
    SELECT
        u.id,
        issue_status.id,
        NEW.title
    FROM
        topics AS issue_status
    INNER JOIN
        updates u
    ON
        u.uuid = NEW.update_uuid
    WHERE
        issue_status.uuid = NEW.issue_status_uuid
    ;

    SELECT RAISE(IGNORE);
END;
