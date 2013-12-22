CREATE TABLE func_new_project(
    update_id integer NOT NULL DEFAULT (currval('updates')),
    id integer NOT NULL DEFAULT (nextval('topics')),
    parent_id integer,
    name varchar(40),
    title varchar(1024) NOT NULL DEFAULT ''
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

/*
    UPDATE
        updates_pending
    SET
        terms = terms || (
            SELECT
                'new_project:' || x'0A'
                || 'uuid:' || COALESCE(topics.uuid, '') || x'0A'
                || 'parent_uuid:' || COALESCE(parent.uuid, '') || x'0A'
                || 'name:' || COALESCE(NEW.name, '') || x'0A'
                || 'title:' || COALESCE(NEW.title, '') || x'0A'
            FROM
                topics
            LEFT JOIN
                topics AS parent
            ON
                parent.id = NEW.parent_id
            WHERE
                topics.id = NEW.project_id
        )
    WHERE
        update_id = NEW.update_id
    ;
*/

    -- We don't insert into project_updates because the caller has to
    -- do it with a valid status_id (which cannot be known until later)
    -- before the end of the transaction.

    SELECT RAISE(IGNORE);
END;
