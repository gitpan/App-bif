CREATE TABLE func_new_hub(
    update_id INTEGER NOT NULL,
    id INTEGER NOT NULL DEFAULT (nextval('topics')),
    alias VARCHAR(40),
    local INTEGER
);

CREATE TRIGGER
    bi_func_new_hub_1
BEFORE INSERT ON
    func_new_hub
FOR EACH ROW
BEGIN

    SELECT debug(
        'TRIGGER bi_func_new_hub_1',
        NEW.id,
        NEW.update_id,
        NEW.alias,
        NEW.local
    );

    INSERT INTO
        topics(
            id,
            first_update_id,
            kind,
            ctime,
            ctimetz,
            mtime,
            mtimetz,
            lang,
            uuid
        )
    SELECT
        NEW.id,
        NEW.update_id,
        'hub',
        updates.mtime,
        updates.mtimetz,
        updates.mtime,
        updates.mtimetz,
        updates.lang,
        sha1_hex(
            'hub',
            updates.author,
            updates.email,
            updates.lang,
            updates.message,
            updates.mtime,
            updates.mtimetz
        )
    FROM
        updates
    WHERE
        updates.id = NEW.update_id
    ;

    INSERT INTO hubs(
        id,
        alias,
        local
    )
    VALUES(
        NEW.id,
        COALESCE(NEW.alias, 'TODO'),
        NEW.local
    );

    INSERT INTO
        hub_updates(
            update_id,
            hub_id,
            new
        )
    VALUES(
        NEW.update_id,
        NEW.id,
        1
    );

    SELECT RAISE(IGNORE);
END;
