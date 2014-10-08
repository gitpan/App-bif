CREATE TABLE func_update_task(
    change_id INTEGER NOT NULL,
    id INTEGER NOT NULL,
    status_id INTEGER,
    title VARCHAR
);

CREATE TRIGGER
    func_update_task_bi_1
BEFORE INSERT ON
    func_update_task
FOR EACH ROW BEGIN

    SELECT debug(
        'TRIGGER func_update_task_bi_1',
        NEW.id,
        NEW.change_id,
        NEW.status_id,
        NEW.title
    );

    INSERT INTO
        task_deltas(
            change_id,
            task_id,
            status_id,
            title
        )
    VALUES(
        NEW.change_id,
        NEW.id,
        NEW.status_id,
        NEW.title
    );

    SELECT RAISE(IGNORE);

END;
