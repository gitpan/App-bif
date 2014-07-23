CREATE TABLE func_new_hub(
    update_id INTEGER NOT NULL,
    id INTEGER NOT NULL DEFAULT (nextval('topics')),
    name VARCHAR(128),
    local INTEGER
);

CREATE TRIGGER
    func_new_hub_bi_1
BEFORE INSERT ON
    func_new_hub
FOR EACH ROW
BEGIN

    SELECT debug(
        'TRIGGER func_new_hub_bi_1',
        NEW.id,
        NEW.update_id,
        NEW.name,
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
            updates.mtimetz,
            NEW.name
        )
    FROM
        updates
    WHERE
        updates.id = NEW.update_id
    ;

    INSERT INTO hubs(
        id,
        name,
        local
    )
    VALUES(
        NEW.id,
        NEW.name,
        NEW.local
    );

    INSERT INTO
        hub_deltas(
            update_id,
            hub_id,
            name,
            new
        )
    VALUES(
        NEW.update_id,
        NEW.id,
        NEW.name,
        1
    );

    SELECT RAISE(IGNORE);
END;
