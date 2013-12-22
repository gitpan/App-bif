CREATE TABLE func_import_task(
    task_status_uuid varchar(40),
    title varchar(1024)
);


CREATE TRIGGER
    bi_func_import_task_1
BEFORE INSERT ON
    func_import_task
FOR EACH ROW
BEGIN

    SELECT debug(
        'TRIGGER bi_func_import_task_1',
        NEW.task_status_uuid,
        NEW.title
    );

    INSERT INTO
        func_new_task(
            status_id,
            title
        )
    SELECT
        task_status.id,
        NEW.title
    FROM
        topics AS task_status
    WHERE
        task_status.uuid = NEW.task_status_uuid
    ;

    SELECT RAISE(IGNORE);
END;
