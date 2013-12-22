CREATE TABLE func_import_update(
    uuid char(40) NOT NULL, -- to check later?
    parent_uuid varchar(40),
    author varchar(255) NOT NULL,
    email varchar(255) NOT NULL,
    lang varchar(8) NOT NULL,
    mtime integer NOT NULL,
    mtimetz integer NOT NULL,
    message text NOT NULL
);


-- TODO Can all of these func_imports be BEFORE INSERT triggers?
-- The question is how far up the stack a RAISE(IGNORE) goes.
CREATE TRIGGER
    bi_func_import_update_1
BEFORE INSERT ON
    func_import_update
FOR EACH ROW
BEGIN

    SELECT debug(
        'TRIGGER bi_func_import_update_1',
        NEW.uuid,
        NEW.parent_uuid,
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
    ;

    SELECT RAISE(IGNORE);
END;
