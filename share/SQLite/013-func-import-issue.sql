CREATE TABLE func_import_issue(
    update_uuid VARCHAR(40) NOT NULL,
    topic_uuid VARCHAR(40) NOT NULL,
    issue_status_uuid VARCHAR(40),
    title VARCHAR(1024)
);


CREATE TRIGGER
    func_import_issue_bi_1
BEFORE INSERT ON
    func_import_issue
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.update_uuid,
        NEW.topic_uuid,
        NEW.issue_status_uuid,
        NEW.title
    );

    INSERT INTO
        func_new_issue(
            update_id,
            topic_id,
            status_id,
            title
        )
    SELECT
        u.id,
        t.id,
        ist.id,
        NEW.title
    FROM
        updates u
    INNER JOIN
        topics t
    ON
        t.uuid = NEW.topic_uuid
    INNER JOIN
        topics ist
    ON
        ist.uuid = NEW.issue_status_uuid
    WHERE
        u.uuid = NEW.update_uuid
    ;

    SELECT RAISE(IGNORE);
END;
