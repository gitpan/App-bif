CREATE TABLE func_import_entity(
    update_uuid VARCHAR(40) NOT NULL,
    kind VARCHAR NOT NULL,
    name VARCHAR NOT NULL
);

CREATE TRIGGER
    func_import_entity_bi_1
BEFORE INSERT ON
    func_import_entity
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.update_uuid,
        NEW.kind,
        NEW.name
    );

    INSERT INTO
        func_new_entity(
            update_id,
            kind,
            name
        )
    SELECT
        u.id,
        NEW.kind,
        NEW.name
    FROM
        updates u
    WHERE
        u.uuid = NEW.update_uuid
    ;

    SELECT RAISE(IGNORE);
END;
