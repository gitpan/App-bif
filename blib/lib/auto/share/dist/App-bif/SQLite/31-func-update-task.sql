CREATE TABLE func_update_task(
    id INTEGER NOT NULL,
    update_id INTEGER NOT NULL DEFAULT (currval('updates')),
    status_id INTEGER,
    title VARCHAR
);

CREATE TRIGGER
    bi_func_update_task_1
BEFORE INSERT ON
    func_update_task
FOR EACH ROW BEGIN

    SELECT debug(
        'TRIGGER bi_func_update_task_1',
        NEW.id,
        NEW.update_id,
        NEW.status_id,
        NEW.title
    );

    INSERT INTO
        task_updates(
            update_id,
            task_id,
            status_id,
            title
        )
    VALUES(
        NEW.update_id,
        NEW.id,
        NEW.status_id,
        NEW.title
    );

    SELECT RAISE(IGNORE);

END;
