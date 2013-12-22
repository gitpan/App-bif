CREATE TABLE func_update_project_status(
    update_id integer NOT NULL DEFAULT (currval('updates')),
    id integer NOT NULL,
    status varchar(40),
    rank integer
);

CREATE TRIGGER
    bi_func_update_project_status_1
BEFORE INSERT ON
    func_update_project_status
FOR EACH ROW BEGIN

    SELECT debug(
        'TRIGGER bi_func_update_project_status_1',
        NEW.update_id,
        NEW.id,
        NEW.status,
        NEW.rank
    );

    INSERT INTO
        project_status_updates(
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
