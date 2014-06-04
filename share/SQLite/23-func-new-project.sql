CREATE TABLE func_new_project(
    update_id INTEGER NOT NULL,
    id INTEGER NOT NULL DEFAULT (nextval('topics')),
    parent_id INTEGER,
    name VARCHAR(40),
    title VARCHAR(1024) NOT NULL DEFAULT ''
);

CREATE TRIGGER
    func_new_project_bi_1
BEFORE INSERT ON
    func_new_project
FOR EACH ROW
BEGIN

    SELECT debug(
        'TRIGGER func_new_project_bi_1',
        NEW.id,
        NEW.update_id,
        NEW.parent_id,
        NEW.name,
        NEW.title
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
            title
        )
    VALUES(
        NEW.id,
        NEW.parent_id,
        NEW.name,
        NEW.title
    );

    INSERT INTO
        project_deltas(
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
