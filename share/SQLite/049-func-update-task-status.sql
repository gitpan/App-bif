CREATE TABLE func_change_task_status(
    change_id INTEGER NOT NULL,
    id INTEGER NOT NULL,
    status VARCHAR(40),
    rank INTEGER,
    def INTEGER
);

CREATE TRIGGER
    func_change_task_status_bi_1
BEFORE INSERT ON
    func_change_task_status
FOR EACH ROW BEGIN

    SELECT debug(
        'TRIGGER func_change_task_status_bi_1',
        NEW.change_id,
        NEW.id,
        NEW.status,
        NEW.rank,
        NEW.def
    );

    INSERT INTO
        task_status_deltas(
            id,
            task_status_id,
            status,
            rank,
            def
        )
    VALUES(
        NEW.change_id,
        NEW.id,
        NEW.status,
        NEW.rank,
        NEW.def
    );

    SELECT RAISE(IGNORE);

END;
