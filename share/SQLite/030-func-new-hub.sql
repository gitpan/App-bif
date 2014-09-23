CREATE TABLE func_new_hub(
    change_id INTEGER NOT NULL,
    id INTEGER NOT NULL DEFAULT (nextval('topics')),
    name VARCHAR(128),
    local INTEGER
);

CREATE TRIGGER
    func_new_hub_bi_1
BEFORE INSERT ON
    func_new_hub
FOR EACH ROW
BEGIN

    SELECT debug(
        'TRIGGER func_new_hub_bi_1',
        NEW.id,
        NEW.change_id,
        NEW.name,
        NEW.local
    );


    INSERT INTO hubs(
        id,
        name,
        local
    )
    VALUES(
        NEW.id,
        NEW.name,
        NEW.local
    );

    INSERT INTO
        hub_deltas(
            change_id,
            hub_id,
            name,
            new
        )
    VALUES(
        NEW.change_id,
        NEW.id,
        NEW.name,
        1
    );

    SELECT RAISE(IGNORE);
END;
