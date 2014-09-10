CREATE TABLE func_import_entity_delta(
    update_uuid VARCHAR(40) NOT NULL,
    entity_uuid VARCHAR(40) NOT NULL,
    name VARCHAR,
    contact_uuid VARCHAR(40),
    default_contact_method_uuid VARCHAR(40)
);

CREATE TRIGGER
    func_import_entity_delta_bi_1
BEFORE INSERT ON
    func_import_entity_delta
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.update_uuid,
        NEW.entity_uuid,
        NEW.name,
        NEW.contact_uuid,
        NEW.default_contact_method_uuid
    );

    INSERT INTO
        entity_deltas(
            update_id,
            entity_id,
            name,
            contact_id,
            default_contact_method_id
        )
    SELECT
        u.id,
        e.id,
        NEW.name,
        c.id,
        dcm.id
        
    FROM
        topics e
    INNER JOIN
        updates u
    ON
        u.uuid = NEW.update_uuid
    LEFT JOIN
        topics c
    ON
        c.uuid = NEW.contact_uuid
    LEFT JOIN
        topics dcm
    ON
        dcm.uuid = NEW.default_contact_method_uuid
    WHERE
        e.uuid = NEW.entity_uuid
    ;

    SELECT RAISE(IGNORE);
END;
