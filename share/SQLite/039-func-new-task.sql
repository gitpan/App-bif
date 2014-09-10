CREATE TABLE func_new_task(
    update_id INTEGER NOT NULL,
    id INTEGER NOT NULL DEFAULT (nextval('topics')),
    status_id INTEGER NOT NULL,
    title VARCHAR(1024) NOT NULL DEFAULT ''
);


CREATE TRIGGER
    func_new_task_bi_1
BEFORE INSERT ON
    func_new_task
FOR EACH ROW
BEGIN

    SELECT debug(
        'TRIGGER func_new_task_bi_1',
        NEW.id,
        NEW.status_id,
        NEW.title,
        NEW.update_id
    );

    INSERT INTO tasks(
        id,
        status_id,
        title,
        update_id
    )
    VALUES(
        NEW.id,
        NEW.status_id,
        NEW.title,
        NEW.update_id
    );

    INSERT INTO
        task_deltas(
            status_id,
            task_id,
            new,
            title,
            update_id
        )
    VALUES(
        NEW.status_id,
        NEW.id,
        1,
        NEW.title,
        NEW.update_id
    );

    SELECT RAISE(IGNORE);
END;
