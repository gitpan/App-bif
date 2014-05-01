CREATE TABLE func_new_hub_location(
    id INTEGER NOT NULL DEFAULT (nextval('topics')),
    update_id INTEGER NOT NULL DEFAULT (currval('updates')),
    hub_id INTEGER NOT NULL,
    location VARCHAR NOT NULL
);

CREATE TRIGGER
    bi_func_new_hub_location_1
BEFORE INSERT ON
    func_new_hub_location
FOR EACH ROW
BEGIN

    SELECT debug(
        'TRIGGER bi_func_new_hub_location_1',
        NEW.id,
        NEW.hub_id,
        NEW.location
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
        'hub_location',
        updates.mtime,
        updates.mtimetz,
        updates.mtime,
        updates.mtimetz,
        updates.lang,
        sha1_hex(
            'hub_location',
            updates.author,
            updates.email,
            updates.lang,
            updates.message,
            updates.mtime,
            updates.mtimetz,
            NEW.location,
            repo.uuid
        )
    FROM
        updates
    INNER JOIN
        topics AS repo
    ON
        repo.id = NEW.hub_id
    WHERE
        updates.id = NEW.update_id
    ;

    INSERT INTO
        hub_locations(
            id,
            hub_id,
            location
        )
    VALUES(
        NEW.id,
        NEW.hub_id,
        NEW.location
    );

    INSERT INTO
        hub_location_updates(
            update_id,
            hub_location_id,
            new,
            location
        )
    VALUES(
        NEW.update_id,
        NEW.id,
        1,
        NEW.location
    );

    SELECT RAISE(IGNORE);
END;