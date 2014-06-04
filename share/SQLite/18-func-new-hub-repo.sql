CREATE TABLE func_new_hub_repo(
    update_id INTEGER NOT NULL,
    id INTEGER NOT NULL DEFAULT (nextval('topics')),
    hub_id INTEGER NOT NULL,
    location VARCHAR NOT NULL
);

CREATE TRIGGER
    func_new_hub_repo_bi_1
BEFORE INSERT ON
    func_new_hub_repo
FOR EACH ROW
BEGIN

    SELECT debug(
        'TRIGGER func_new_hub_repo_bi_1',
        NEW.id,
        NEW.update_id,
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
        'hub_repo',
        updates.mtime,
        updates.mtimetz,
        updates.mtime,
        updates.mtimetz,
        updates.lang,
        sha1_hex(
            'hub_repo',
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
        hub_repos(
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
        hub_repo_deltas(
            update_id,
            hub_repo_id,
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
