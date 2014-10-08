CREATE TABLE func_import_project_status_delta(
    change_uuid VARCHAR(40) NOT NULL,
    project_status_uuid VARCHAR(40) NOT NULL,
    status VARCHAR(40),
    rank INTEGER,
    def INTEGER
);


CREATE TRIGGER
    func_import_project_status_delta_bi_1
BEFORE INSERT ON
    func_import_project_status_delta
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.change_uuid,
        NEW.project_status_uuid,
        NEW.status,
        NEW.rank,
        NEW.def
    );

    INSERT INTO
        func_update_project_status(
            change_id,
            status,
            rank,
            def
        )
    SELECT
        c.id,
        project_status.id,
        NEW.status,
        NEW.rank,
        NEW.def
    FROM
        topics AS project_status
    INNER JOIN
        changes c
    ON
        c.uuid = NEW.change_uuid
    WHERE
        project_status.uuid = NEW.project_status_uuid
    ;

    SELECT RAISE(IGNORE);
END;
