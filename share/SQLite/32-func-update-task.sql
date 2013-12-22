CREATE TABLE func_update_task(
    id integer NOT NULL,
    update_id integer NOT NULL DEFAULT (currval('updates')),
    status_id integer,
    title varchar
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
