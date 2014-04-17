CREATE TABLE func_import_issue(
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
        'TRIGGER bi_func_import_issue_1',
        NEW.issue_status_uuid,
        NEW.title
    );

    INSERT INTO
        func_new_issue(
            status_id,
            title
        )
    SELECT
        issue_status.id,
        NEW.title
    FROM
        topics AS issue_status
    WHERE
        issue_status.uuid = NEW.issue_status_uuid
    ;

    SELECT RAISE(IGNORE);
END;
