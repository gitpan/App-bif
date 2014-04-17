CREATE TABLE func_import_task_status_update(
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
        'TRIGGER bi_func_import_task_status_update_1',
        NEW.task_status_uuid,
        NEW.status,
        NEW.rank,
        NEW.def
    );

    INSERT INTO
        func_update_task_status(
            status,
            rank,
            def
        )
    SELECT
        task_status.id,
        NEW.status,
        NEW.rank,
        NEW.def
    FROM
        topics AS task_status
    WHERE
        task_status.uuid = NEW.task_status_uuid
    ;

    SELECT RAISE(IGNORE);
END;
