CREATE TABLE func_update_issue_status(
    update_id INTEGER NOT NULL,
    id INTEGER NOT NULL,
    status VARCHAR(40),
    rank INTEGER,
    def INTEGER
);

-- TODO  turn into a BEFORE trigger
CREATE TRIGGER
    func_update_issue_status_bi_1
BEFORE INSERT ON
    func_update_issue_status
FOR EACH ROW BEGIN

    SELECT debug(
        'TRIGGER func_update_issue_status_bi_1',
        NEW.id,
        NEW.update_id,
        NEW.status,
        NEW.rank,
        NEW.def
    );

    INSERT INTO
        issue_status_deltas(
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
