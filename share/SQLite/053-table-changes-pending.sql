CREATE TABLE changes_pending(
    change_id INTEGER NOT NULL UNIQUE,
    terms VARCHAR NOT NULL,
    resolve INTEGER,
    FOREIGN KEY(change_id) REFERENCES changes(id) ON DELETE CASCADE
);

CREATE TRIGGER
    changes_pending_bi_1
BEFORE INSERT ON
    changes_pending
FOR EACH ROW
BEGIN
    SELECT debug(
        'TRIGGER changes_pending_bi_1',
        NEW.change_id,
        NEW.terms
    );
END;

CREATE TRIGGER
    changes_pending_bu_1
BEFORE UPDATE ON
    changes_pending
FOR EACH ROW WHEN
    NEW.resolve = 1
BEGIN

    SELECT debug(
        'TRIGGER changes_pending_bu_1',
        NEW.change_id,
        NEW.terms
    );

    UPDATE
        changes
    SET
        uuid = sha1_hex(NEW.terms)
    WHERE
        id = NEW.change_id
    ;

/*
    -- don't do this until development stops
    DELETE FROM
        changes_pending
    WHERE
        change_id = NEW.change_id
    ;

    SELECT RAISE(IGNORE);
*/

END;
