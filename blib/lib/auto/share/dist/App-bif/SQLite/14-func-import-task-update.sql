CREATE TABLE func_import_task_update(
    task_uuid VARCHAR(40),
    task_status_uuid VARCHAR(40),
    title VARCHAR(1024)
);


CREATE TRIGGER
    bi_func_import_task_update_1
BEFORE INSERT ON
    func_import_task_update
FOR EACH ROW
BEGIN

    SELECT debug(
        'TRIGGER bi_func_import_task_update_1',
        NEW.task_uuid,
        NEW.task_status_uuid,
        NEW.title
    );

    INSERT INTO
        func_update_task(
            id,
            status_id,
            title
        )
    SELECT
        tasks.id,
        task_status.id,
        NEW.title
    FROM
        (SELECT 1)
    LEFT JOIN
        topics AS tasks
    ON
        tasks.uuid = NEW.task_uuid
    LEFT JOIN
        topics AS task_status
    ON
        task_status.uuid = NEW.task_status_uuid
    ;

    SELECT RAISE(IGNORE);
END;
