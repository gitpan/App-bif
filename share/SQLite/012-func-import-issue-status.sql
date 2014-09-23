CREATE TABLE func_import_issue_status(
    change_uuid VARCHAR(40) NOT NULL,
    topic_uuid VARCHAR(40) NOT NULL,
    project_uuid VARCHAR(40) NOT NULL,
    status VARCHAR(40) NOT NULL,
    rank INTEGER NOT NULL,
    def INTEGER
);


CREATE TRIGGER
    func_import_issue_status_bi_1
BEFORE INSERT ON
    func_import_issue_status
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.change_uuid,
        NEW.topic_uuid,
        NEW.project_uuid,
        NEW.status,
        NEW.rank,
        NEW.def
    );

    INSERT INTO
        func_new_issue_status(
            change_id,
            id,
            project_id,
            status,
            rank,
            def
        )
    SELECT
        c.id,
        t.id,
        p.id,
        NEW.status,
        NEW.rank,
        NEW.def
    FROM
        changes c
    INNER JOIN
        topics t
    ON
        t.uuid = NEW.topic_uuid
    INNER JOIN
        topics p
    ON
        p.uuid = NEW.project_uuid
    WHERE
        c.uuid = NEW.change_uuid
    ;

    SELECT RAISE(IGNORE);
END;
