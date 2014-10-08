CREATE TABLE func_update_plan(
    change_id INTEGER NOT NULL,
    id INTEGER NOT NULL,
    name VARCHAR,
    add_remove INTEGER,
    host_id INTEGER
);

CREATE TRIGGER
    func_update_plan_bi_1
BEFORE INSERT ON
    func_update_plan
FOR EACH ROW BEGIN

    SELECT debug(
        NEW.id,
        NEW.change_id,
        NEW.name,
        NEW.add_remove,
        NEW.host_id
    );

    INSERT INTO
        plan_deltas(
            change_id,
            plan_id,
            name,
            add_remove,
            host_id
        )
    VALUES(
        NEW.change_id,
        NEW.id,
        NEW.name,
        NEW.add_remove,
        NEW.host_id
    );

    SELECT RAISE(IGNORE);

END;
