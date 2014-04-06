CREATE TABLE updates_pending(
    update_id INTEGER NOT NULL UNIQUE,
    terms VARCHAR NOT NULL,
    resolve INTEGER,
    FOREIGN KEY(update_id) REFERENCES updates(id) ON DELETE CASCADE
);

CREATE TRIGGER
    bi_updates_pending_1
BEFORE INSERT ON
    updates_pending
FOR EACH ROW
BEGIN
    SELECT debug(
        'TRIGGER bi_updates_pending_1',
        NEW.update_id,
        NEW.terms
    );
END;

CREATE TRIGGER
    bu_updates_pending_1
BEFORE UPDATE ON
    updates_pending
FOR EACH ROW WHEN
    NEW.resolve = 1
BEGIN

    SELECT debug(
        'TRIGGER bu_updates_pending_1',
        NEW.update_id,
        NEW.terms
    );

    UPDATE
        updates
    SET
        uuid = sha1_hex(OLD.terms)
    WHERE
        id = OLD.update_id
    ;

    UPDATE
        updates
    SET
        prefix = SUBSTR(uuid, 1, 5)
    WHERE
        id = OLD.update_id
    ;

    DELETE FROM
        updates_pending
    WHERE
        update_id = NEW.update_id
    ;

    SELECT RAISE(IGNORE);
END;
