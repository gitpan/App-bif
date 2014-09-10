CREATE TABLE func_new_project_status(
    update_id INTEGER NOT NULL,
    id INTEGER NOT NULL DEFAULT (nextval('topics')),
    project_id INTEGER,
    status VARCHAR(40) NOT NULL,
    rank INTEGER NOT NULL
);

CREATE TRIGGER
    func_new_project_status_bi_1
BEFORE INSERT ON
    func_new_project_status
FOR EACH ROW BEGIN

    SELECT debug(
        'TRIGGER func_new_project_status_bi_1',
        NEW.id,
        NEW.project_id,
        NEW.status
    );

    INSERT INTO
        project_status(
            id,
            project_id,
            status,
            rank
        )
    VALUES(
        NEW.id,
        NEW.project_id,
        NEW.status,
        NEW.rank
    );

    INSERT INTO
        project_status_deltas(
            update_id,
            project_status_id,
            new,
            status,
            rank
        )
    VALUES(
        NEW.update_id,
        NEW.id,
        1,
        NEW.status,
        NEW.rank
    );

    SELECT RAISE(IGNORE);
END;
