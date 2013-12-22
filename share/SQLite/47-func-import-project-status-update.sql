CREATE TABLE func_import_project_status_update(
    project_status_uuid varchar(40) NOT NULL,
    status varchar(40),
    rank integer,
    def integer
);


CREATE TRIGGER
    bi_func_import_project_status_update_1
BEFORE INSERT ON
    func_import_project_status_update
FOR EACH ROW
BEGIN

    SELECT debug(
        'TRIGGER bi_func_import_project_status_update_1',
        NEW.project_status_uuid,
        NEW.status,
        NEW.rank,
        NEW.def
    );

    INSERT INTO
        func_update_project_status(
            status,
            rank,
            def
        )
    SELECT
        project_status.id,
        NEW.status,
        NEW.rank,
        NEW.def
    FROM
        topics AS project_status
    WHERE
        project_status.uuid = NEW.project_status_uuid
    ;

    SELECT RAISE(IGNORE);
END;
