CREATE TABLE func_import_task_status_update(
    update_uuid VARCHAR(40) NOT NULL,
    task_status_uuid VARCHAR(40) NOT NULL,
    status VARCHAR(40),
    rank INTEGER,
    def INTEGER
);


CREATE TRIGGER
    bi_func_import_task_status_update_1
BEFORE INSERT ON
    func_import_task_status_update
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.update_uuid,
        NEW.task_status_uuid,
        NEW.status,
        NEW.rank,
        NEW.def
    );

    INSERT INTO
        func_update_task_status(
            update_id,
            status,
            rank,
            def
        )
    SELECT
        u.id,
        task_status.id,
        NEW.status,
        NEW.rank,
        NEW.def
    FROM
        topics AS task_status
    INNER JOIN
        updates u
    ON
        u.uuid = NEW.update_uuid
    WHERE
        task_status.uuid = NEW.task_status_uuid
    ;

    SELECT RAISE(IGNORE);
END;
