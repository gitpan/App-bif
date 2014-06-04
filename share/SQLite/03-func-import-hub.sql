CREATE TABLE func_import_hub(
    update_uuid VARCHAR(40) NOT NULL,
    name VARCHAR(128) NOT NULL
);

CREATE TRIGGER
    func_import_hub_bi_1
BEFORE INSERT ON
    func_import_hub
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.update_uuid,
        NEW.name
    );

    INSERT INTO
        func_new_hub(
            update_id,
            name
        )
    SELECT
        u.id,
        NEW.name
    FROM
        updates u
    WHERE
        u.uuid = NEW.update_uuid
    ;

    SELECT RAISE(IGNORE);
END;
