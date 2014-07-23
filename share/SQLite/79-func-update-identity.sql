-- TODO should callers actually use func_update_entity?
CREATE TABLE func_update_identity(
    update_id INTEGER NOT NULL,
    id INTEGER NOT NULL,
    name VARCHAR,
    contact_id INTEGER,
    default_contact_method_id INTEGER
);

CREATE TRIGGER
    func_update_identity_bi_1
BEFORE INSERT ON
    func_update_identity
FOR EACH ROW BEGIN

    SELECT debug(
        NEW.id,
        NEW.update_id,
        NEW.name,
        NEW.contact_id,
        NEW.default_contact_method_id
    );

    INSERT INTO
        entity_deltas(
            update_id,
            entity_id,
            name,
            contact_id,
            default_contact_method_id
        )
    VALUES(
        NEW.update_id,
        NEW.id,
        NEW.name,
        NEW.contact_id,
        NEW.default_contact_method_id
    );

    SELECT RAISE(IGNORE);

END;
