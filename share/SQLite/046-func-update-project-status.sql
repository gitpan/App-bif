CREATE TABLE func_update_project_status(
    update_id INTEGER NOT NULL,
    id INTEGER NOT NULL,
    status VARCHAR(40),
    rank INTEGER
);

CREATE TRIGGER
    func_update_project_status_bi_1
BEFORE INSERT ON
    func_update_project_status
FOR EACH ROW BEGIN

    SELECT debug(
        'TRIGGER func_update_project_status_bi_1',
        NEW.update_id,
        NEW.id,
        NEW.status,
        NEW.rank
    );

    INSERT INTO
        project_status_deltas(
            update_id,
            project_status_id,
            status,
            rank
        )
    VALUES(
        NEW.update_id,
        NEW.id,
        NEW.status,
        NEW.rank
    );

    SELECT RAISE(IGNORE);

END;
