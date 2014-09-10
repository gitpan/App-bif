CREATE TABLE func_import_identity(
    update_uuid VARCHAR(40) NOT NULL,
    entity_uuid VARCHAR(40) NOT NULL
);

CREATE TRIGGER
    func_import_identity_bi_1
BEFORE INSERT ON
    func_import_identity
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.update_uuid,
        NEW.entity_uuid
    );

    INSERT INTO
        func_new_identity(
            update_id,
            id
        )
    SELECT
        u.id,
        e.id
    FROM
        updates u
    INNER JOIN
        topics e
    ON
        e.uuid = NEW.entity_uuid
    WHERE
        u.uuid = NEW.update_uuid
    ;

    SELECT RAISE(IGNORE);
END;
