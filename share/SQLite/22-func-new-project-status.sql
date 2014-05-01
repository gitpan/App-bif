CREATE TABLE func_new_project_status(
    id INTEGER NOT NULL DEFAULT (nextval('topics')),
    update_id INTEGER NOT NULL DEFAULT (currval('updates')),
    project_id INTEGER,
    status VARCHAR(40) NOT NULL,
    rank INTEGER NOT NULL
);

CREATE TRIGGER
    bi_func_new_project_status_1
BEFORE INSERT ON
    func_new_project_status
FOR EACH ROW BEGIN

    SELECT debug(
        'TRIGGER bi_func_new_project_status_1',
        NEW.id,
        NEW.project_id,
        NEW.status
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
        'project_status',
        updates.mtime,
        updates.mtimetz,
        updates.mtime,
        updates.mtimetz,
        updates.lang,
        sha1_hex(
            'project_status',
            updates.author,
            updates.email,
            updates.lang,
            updates.message,
            updates.mtime,
            updates.mtimetz,
            NEW.rank,
            NEW.status,
            project.uuid
        )
    FROM
        updates
    INNER JOIN
        topics AS project
    ON
        project.id = NEW.project_id
    WHERE
        updates.id = NEW.update_id
    ;

    INSERT INTO
        project_status(
            id,
            project_id,
            status,
            rank
        )
    VALUES(
        NEW.id,
        NEW.project_id,
        NEW.status,
        NEW.rank
    );

    INSERT INTO
        project_status_updates(
            update_id,
            project_status_id,
            new,
            status,
            rank
        )
    VALUES(
        NEW.update_id,
        NEW.id,
        1,
        NEW.status,
        NEW.rank
    );

    SELECT RAISE(IGNORE);
END;
