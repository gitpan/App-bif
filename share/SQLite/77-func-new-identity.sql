CREATE TABLE func_new_identity(
    update_id INTEGER NOT NULL,
    id INTEGER NOT NULL DEFAULT (nextval('topics')),
    self INTEGER
);


CREATE TRIGGER
    func_new_identity_bi_1
BEFORE INSERT ON
    func_new_identity
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.update_id,
        NEW.id,
        NEW.self
    );

    INSERT INTO identities(
        id
    )
    VALUES(
        NEW.id
    );

    INSERT INTO
        identity_deltas(
            update_id,
            identity_id,
            new
        )
    VALUES(
        NEW.update_id,
        NEW.id,
        1
    );

    INSERT INTO
        identity_self(id)
    SELECT
        NEW.id
    WHERE
        NEW.self = 1
    ;

    /*
        Set updates.identity_id to this identity to trigger an entry in
        updates_pending.terms for identity_uuid.
    */

    UPDATE
        updates
    SET
        identity_id = NEW.id
    WHERE
        id = NEW.update_id
    ;


    SELECT RAISE(IGNORE);
END;
