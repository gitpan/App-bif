CREATE TABLE func_import_update(
    uuid char(40) NOT NULL,
    parent_uuid VARCHAR(40),
    identity_uuid VARCHAR(40),
    author VARCHAR(255),
    email VARCHAR(255),
    lang VARCHAR(8) NOT NULL,
    mtime INTEGER NOT NULL,
    mtimetz INTEGER NOT NULL,
    message text NOT NULL,
    action VARCHAR --TODO make NOT NULL
);


CREATE TRIGGER
    func_import_update_bi_1
BEFORE INSERT ON
    func_import_update
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.uuid,
        NEW.parent_uuid,
        NEW.identity_uuid,
        NEW.author,
        NEW.email,
        NEW.mtime,
        NEW.mtimetz,
        NEW.lang,
        NEW.action
    );

    INSERT INTO
        updates(
            id,
            uuid,
            parent_id,
            identity_id,
            author,
            email,
            mtime,
            mtimetz,
            lang,
            message,
            action
        )
    SELECT
        nextval('updates'),
        NEW.uuid,
        updates.id,
        COALESCE(t.id,-1),
        NEW.author,
        NEW.email,
        NEW.mtime,
        NEW.mtimetz,
        NEW.lang,
        NEW.message,
        NEW.action
    FROM

        /*
            If was is the first update in a repo then there is no
            identity yet matching identity_uuid, and parent_uuid may be
            NULL, so we (SELECT 1) to ensure that the query generates
            a row regardless.
        */

        (SELECT 1)
    LEFT JOIN
        updates
    ON
        updates.uuid = NEW.parent_uuid
    LEFT JOIN
        topics t
    ON
        t.uuid = NEW.identity_uuid
    ;

    SELECT RAISE(IGNORE);
END;
