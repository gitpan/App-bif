CREATE TABLE func_update_hub(
    change_id INTEGER NOT NULL,
    id INTEGER NOT NULL,
    name VARCHAR
);

CREATE TRIGGER
    func_update_hub_bi_1
BEFORE INSERT ON
    func_update_hub
FOR EACH ROW BEGIN

    SELECT debug(
        NEW.id,
        NEW.change_id,
        NEW.name
    );

    INSERT INTO
        hub_deltas(
            change_id,
            hub_id,
            name
        )
    VALUES(
        NEW.change_id,
        NEW.id,
        NEW.name
    );

    SELECT RAISE(IGNORE);

END;
