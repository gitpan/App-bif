CREATE TABLE func_import_task(
    update_uuid VARCHAR(40) NOT NULL,
    task_status_uuid VARCHAR(40),
    title VARCHAR(1024)
);


CREATE TRIGGER
    func_import_task_bi_1
BEFORE INSERT ON
    func_import_task
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.update_uuid,
        NEW.task_status_uuid,
        NEW.title
    );

    INSERT INTO
        func_new_task(
            update_id,
            status_id,
            title
        )
    SELECT
        u.id,
        task_status.id,
        NEW.title
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
