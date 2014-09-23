CREATE TABLE func_import_task(
    change_uuid VARCHAR(40) NOT NULL,
    topic_uuid VARCHAR(40) NOT NULL,
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
        NEW.change_uuid,
        NEW.topic_uuid,
        NEW.task_status_uuid,
        NEW.title
    );

    INSERT INTO
        func_new_task(
            change_id,
            id,
            status_id,
            title
        )
    SELECT
        c.id,
        t.id,
        ts.id,
        NEW.title
    FROM
        changes c
    INNER JOIN
        topics t
    ON
        t.uuid = NEW.topic_uuid
    INNER JOIN
        topics ts
    ON
        ts.uuid = NEW.task_status_uuid
    WHERE
        c.uuid = NEW.change_uuid
    ;

    SELECT RAISE(IGNORE);
END;
