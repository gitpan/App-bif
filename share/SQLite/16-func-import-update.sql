CREATE TABLE func_import_update(
    uuid char(40) NOT NULL, -- to check later?
    parent_uuid VARCHAR(40),
    identity_uuid VARCHAR(40),
    author VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    lang VARCHAR(8) NOT NULL,
    mtime INTEGER NOT NULL,
    mtimetz INTEGER NOT NULL,
    message text NOT NULL
);


CREATE TRIGGER
    func_import_update_bi_1
BEFORE INSERT ON
    func_import_update
FOR EACH ROW
BEGIN

    SELECT debug(
        'TRIGGER func_import_update_bi_1',
        NEW.uuid,
        NEW.parent_uuid,
        NEW.identity_uuid,
        NEW.author,
        NEW.email,
        NEW.mtime,
        NEW.mtimetz,
        NEW.lang
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
            message
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
        NEW.message
    FROM
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
