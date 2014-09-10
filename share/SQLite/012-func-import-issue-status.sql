CREATE TABLE func_import_issue_status(
    update_uuid VARCHAR(40) NOT NULL,
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
        NEW.update_uuid,
        NEW.topic_uuid,
        NEW.project_uuid,
        NEW.status,
        NEW.rank,
        NEW.def
    );

    INSERT INTO
        func_new_issue_status(
            update_id,
            id,
            project_id,
            status,
            rank,
            def
        )
    SELECT
        u.id,
        t.id,
        p.id,
        NEW.status,
        NEW.rank,
        NEW.def
    FROM
        updates u
    INNER JOIN
        topics t
    ON
        t.uuid = NEW.topic_uuid
    INNER JOIN
        topics p
    ON
        p.uuid = NEW.project_uuid
    WHERE
        u.uuid = NEW.update_uuid
    ;

    SELECT RAISE(IGNORE);
END;
