CREATE TABLE func_import_issue_status_update(
    update_uuid VARCHAR(40) NOT NULL,
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
        NEW.update_uuid,
        NEW.issue_status_uuid,
        NEW.status,
        NEW.rank,
        NEW.def
    );

    INSERT INTO
        func_update_issue_status(
            update_id,
            status,
            rank,
            def
        )
    SELECT
        u.id,
        issue_status.id,
        NEW.status,
        NEW.rank,
        NEW.def
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
