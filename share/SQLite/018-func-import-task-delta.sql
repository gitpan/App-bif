CREATE TABLE func_import_task_delta(
    change_uuid VARCHAR(40) NOT NULL,
    task_uuid VARCHAR(40),
    task_status_uuid VARCHAR(40),
    title VARCHAR(1024)
);


CREATE TRIGGER
    func_import_task_delta_bi_1
BEFORE INSERT ON
    func_import_task_delta
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.change_uuid,
        NEW.task_uuid,
        NEW.task_status_uuid,
        NEW.title
    );

    INSERT INTO
        func_update_task(
            change_id,
            id,
            status_id,
            title
        )
    SELECT
        c.id,
        tasks.id,
        task_status.id,
        NEW.title
    FROM
        (SELECT 1)
    INNER JOIN
        changes c
    ON
        c.uuid = NEW.change_uuid
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
