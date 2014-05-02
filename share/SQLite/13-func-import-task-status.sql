CREATE TABLE func_import_task_status(
    update_uuid VARCHAR(40) NOT NULL,
    project_uuid VARCHAR(40) NOT NULL,
    status VARCHAR(40) NOT NULL,
    rank INTEGER NOT NULL,
    def INTEGER
);


CREATE TRIGGER
    bi_func_import_task_status_1
BEFORE INSERT ON
    func_import_task_status
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.update_uuid,
        NEW.project_uuid,
        NEW.status,
        NEW.rank,
        NEW.def
    );

    INSERT INTO
        func_new_task_status(
            update_id,
            project_id,
            status,
            rank,
            def
        )
    SELECT
        u.id,
        projects.id,
        NEW.status,
        NEW.rank,
        NEW.def
    FROM
        topics AS projects
    INNER JOIN
        updates u
    ON
        u.uuid = NEW.update_uuid
    WHERE
        projects.uuid = NEW.project_uuid
    ;

    SELECT RAISE(IGNORE);
END;
