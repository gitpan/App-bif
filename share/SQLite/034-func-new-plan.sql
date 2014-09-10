CREATE TABLE func_new_plan(
    update_id INTEGER NOT NULL,
    id INTEGER NOT NULL DEFAULT (nextval('topics')),
    provider_id INTEGER NOT NULL,
    name VARCHAR NOT NULL,
    title VARCHAR NOT NULL
);


CREATE TRIGGER
    func_new_plan_bi_1
BEFORE INSERT ON
    func_new_plan
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.update_id,
        NEW.id,
        NEW.provider_id,
        NEW.name,
        NEW.title
    );


    INSERT INTO plans(
        id,
        provider_id,
        name,
        title
    )
    VALUES(
        NEW.id,
        NEW.provider_id,
        NEW.name,
        NEW.title
    );

    INSERT INTO
        plan_deltas(
            update_id,
            plan_id,
            name,
            new,
            title
        )
    VALUES(
        NEW.update_id,
        NEW.id,
        NEW.name,
        NEW.title,
        1
    );

    SELECT RAISE(IGNORE);
END;
