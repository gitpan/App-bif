CREATE TABLE func_update_issue_status(
    update_id INTEGER NOT NULL,
    id INTEGER NOT NULL,
    status VARCHAR(40),
    rank INTEGER,
    def INTEGER
);

-- TODO  turn into a BEFORE trigger
CREATE TRIGGER
    bi_func_update_issue_status_1
BEFORE INSERT ON
    func_update_issue_status
FOR EACH ROW BEGIN

    SELECT debug(
        'TRIGGER bi_func_update_issue_status_1',
        NEW.id,
        NEW.update_id,
        NEW.status,
        NEW.rank,
        NEW.def
    );

    INSERT INTO
        issue_status_updates(
            id,
            issue_status_id,
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
