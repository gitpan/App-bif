CREATE TABLE func_import_entity_contact_method(
    update_uuid VARCHAR(40) NOT NULL,
    entity_uuid VARCHAR(40) NOT NULL,
    method VARCHAR NOT NULL,
    mvalue VARCHAR NOT NULL
);


CREATE TRIGGER
    func_import_entity_contact_method_bi_1
BEFORE INSERT ON
    func_import_entity_contact_method
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.update_uuid,
        NEW.entity_uuid,
        NEW.method,
        NEW.mvalue
    );

    INSERT INTO
        func_new_entity_contact_method(
            update_id,
            entity_id,
            method,
            mvalue
        )
    SELECT
        u.id,
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
        t.uuid = NEW.entity_uuid
    ;

    SELECT RAISE(IGNORE);
END;
