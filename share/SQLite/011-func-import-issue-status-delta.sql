CREATE TABLE func_import_issue_status_delta(
    change_uuid VARCHAR(40) NOT NULL,
    issue_status_uuid VARCHAR(40) NOT NULL,
    status VARCHAR(40),
    rank INTEGER,
    def INTEGER
);


CREATE TRIGGER
    func_import_issue_status_delta_bi_1
BEFORE INSERT ON
    func_import_issue_status_delta
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.change_uuid,
        NEW.issue_status_uuid,
        NEW.status,
        NEW.rank,
        NEW.def
    );

    INSERT INTO
        func_update_issue_status(
            change_id,
            status,
            rank,
            def
        )
    SELECT
        c.id,
        issue_status.id,
        NEW.status,
        NEW.rank,
        NEW.def
    FROM
        topics AS issue_status
    INNER JOIN
        changes c
    ON
        c.uuid = NEW.change_uuid
    WHERE
        issue_status.uuid = NEW.issue_status_uuid
    ;

    SELECT RAISE(IGNORE);
END;
