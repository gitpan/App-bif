CREATE TABLE func_import_issue_status_update(
    issue_status_uuid VARCHAR(40) NOT NULL,
    status VARCHAR(40),
    rank INTEGER,
    def INTEGER
);


CREATE TRIGGER
    bi_func_import_issue_status_update_1
BEFORE INSERT ON
    func_import_issue_status_update
FOR EACH ROW
BEGIN

    SELECT debug(
        'TRIGGER bi_func_import_issue_status_update_1',
        NEW.issue_status_uuid,
        NEW.status,
        NEW.rank,
        NEW.def
    );

    INSERT INTO
        func_update_issue_status(
            status,
            rank,
            def
        )
    SELECT
        issue_status.id,
        NEW.status,
        NEW.rank,
        NEW.def
    FROM
        topics AS issue_status
    WHERE
        issue_status.uuid = NEW.issue_status_uuid
    ;

    SELECT RAISE(IGNORE);
END;
