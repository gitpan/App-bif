CREATE TABLE func_import_task_status_delta(
    change_uuid VARCHAR(40) NOT NULL,
    task_status_uuid VARCHAR(40) NOT NULL,
    status VARCHAR(40),
    rank INTEGER,
    def INTEGER
);


CREATE TRIGGER
    func_import_task_status_delta_bi_1
BEFORE INSERT ON
    func_import_task_status_delta
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.change_uuid,
        NEW.task_status_uuid,
        NEW.status,
        NEW.rank,
        NEW.def
    );

    INSERT INTO
        func_update_task_status(
            change_id,
            status,
            rank,
            def
        )
    SELECT
        c.id,
        task_status.id,
        NEW.status,
        NEW.rank,
        NEW.def
    FROM
        topics AS task_status
    INNER JOIN
        changes c
    ON
        c.uuid = NEW.change_uuid
    WHERE
        task_status.uuid = NEW.task_status_uuid
    ;

    SELECT RAISE(IGNORE);
END;
