CREATE TABLE func_new_host(
    change_id INTEGER NOT NULL,
    id INTEGER NOT NULL DEFAULT (nextval('topics')),
    provider_id INTEGER NOT NULL,
    name VARCHAR NOT NULL
);


CREATE TRIGGER
    func_new_host_bi_1
BEFORE INSERT ON
    func_new_host
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.change_id,
        NEW.id,
        NEW.provider_id,
        NEW.name
    );


    INSERT INTO hosts(
        id,
        provider_id,
        name
    )
    VALUES(
        NEW.id,
        NEW.provider_id,
        NEW.name
    );

    INSERT INTO
        host_deltas(
            change_id,
            host_id,
            name,
            new
        )
    VALUES(
        NEW.change_id,
        NEW.id,
        NEw.name,
        1
    );

    SELECT RAISE(IGNORE);
END;
