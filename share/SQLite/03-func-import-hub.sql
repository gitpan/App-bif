CREATE TABLE func_import_hub(
    update_uuid VARCHAR(40) NOT NULL,
    location VARCHAR(40) NOT NULL
);

CREATE TRIGGER
    bi_func_import_hub_1
BEFORE INSERT ON
    func_import_hub
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.update_uuid,
        NEW.location
    );

    -- DEFAULT VALUES doesn't work in a trigger?!?
    INSERT INTO
        func_new_hub(
            update_id
        )
    SELECT
        u.id
    FROM
        updates u
    WHERE
        u.uuid = NEW.update_uuid
    ;

    SELECT RAISE(IGNORE);
END;
