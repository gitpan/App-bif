CREATE TABLE func_update_task_status(
    update_id INTEGER NOT NULL DEFAULT (currval('updates')),
    id INTEGER NOT NULL,
    status VARCHAR(40),
    rank INTEGER,
    def INTEGER
);

CREATE TRIGGER
    bi_func_update_task_status_1
BEFORE INSERT ON
    func_update_task_status
FOR EACH ROW BEGIN

    SELECT debug(
        'TRIGGER bi_func_update_task_status_1',
        NEW.update_id,
        NEW.id,
        NEW.status,
        NEW.rank,
        NEW.def
    );

    INSERT INTO
        task_status_updates(
            id,
            task_status_id,
            status,
            rank,
            def
        )
    VALUES(
        NEW.update_id,
        NEW.id,
        NEW.status,
        NEW.rank,
        NEW.def
    );

    SELECT RAISE(IGNORE);

END;
