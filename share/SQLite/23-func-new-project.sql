CREATE TABLE func_new_project(
    update_id INTEGER NOT NULL,
    id INTEGER NOT NULL DEFAULT (nextval('topics')),
    parent_id INTEGER,
    name VARCHAR(40),
    title VARCHAR(1024) NOT NULL DEFAULT '',
    local INTEGER
);

CREATE TRIGGER
    bi_func_new_project_1
BEFORE INSERT ON
    func_new_project
FOR EACH ROW
BEGIN

    SELECT debug(
        'TRIGGER bi_func_new_project_1',
        NEW.id,
        NEW.update_id,
        NEW.parent_id,
        NEW.name,
        NEW.title,
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
        'project',
        updates.mtime,
        updates.mtimetz,
        updates.mtime,
        updates.mtimetz,
        updates.lang,
        sha1_hex(
            'project',
            updates.author,
            updates.email,
            updates.lang,
            updates.message,
            updates.mtime,
            updates.mtimetz,
            NEW.name,
            NEW.title,
            parent.uuid
        )
    FROM
        updates
    LEFT JOIN
        topics AS parent
    ON
        parent.id = NEW.parent_id
    WHERE
        updates.id = NEW.update_id
    ;

    INSERT INTO
        projects(
            id,
            parent_id,
            name,
            title,
            local
        )
    VALUES(
        NEW.id,
        NEW.parent_id,
        NEW.name,
        NEW.title,
        NEW.local
    );

    INSERT INTO
        updates(
            id,
            author,
            email,
            message
        )
    SELECT
        nextval('updates'),
        'bif system',
        'bif system',
        '[hub/project relation: ' || substr(ht.uuid,1,8) || '/' ||
            substr(p.uuid,1,8) || ']'
    FROM
        updates u
    INNER JOIN
        topics p
    ON
        p.id = NEW.id
    INNER JOIN
        hubs h
    ON
        h.local = 1
    INNER JOIN
        topics ht
    ON
        ht.id = h.id
    WHERE
        u.id = NEW.update_id
    ;

    INSERT INTO
        hub_updates(
            update_id,
            hub_id,
            project_id
        )
    SELECT
        currval('updates'),
        h.id,
        NEW.id
    FROM
        hubs h
    WHERE
        h.local = 1
    ;

    INSERT INTO
        project_updates(
            update_id,
            project_id,
            new,
            name,
            title
        )
    VALUES(
        NEW.update_id,
        NEW.id,
        1,
        NEW.name,
        NEW.title
    );

    SELECT RAISE(IGNORE);
END;
