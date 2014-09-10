CREATE TABLE func_import_entity_contact_method_delta(
    update_uuid VARCHAR(40) NOT NULL,
    entity_contact_method_uuid VARCHAR(40) NOT NULL,
    method VARCHAR,
    mvalue VARCHAR
);


CREATE TRIGGER
    func_import_entity_contact_method_delta_bi_1
BEFORE INSERT ON
    func_import_entity_contact_method_delta
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.update_uuid,
        NEW.entity_contact_method_uuid,
        NEW.method,
        NEW.mvalue
    );

    INSERT INTO
        func_update_entity_contact_method(
            update_id,
            entity_contact_method_id,
            method,
            mvalue
        )
    SELECT
        u.uuid,
        t.id,
        NEW.method,
        NEW.mvalue
    FROM
        topics t
    INNER JOIN
        updates u
    ON
        u.uuid = NEW.update_uuid
    WHERE
        t.uuid = NEW.entity_contact_method_uuid
    ;

    SELECT RAISE(IGNORE);
END;
