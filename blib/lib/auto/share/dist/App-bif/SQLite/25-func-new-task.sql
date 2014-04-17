CREATE TABLE func_new_task(
    id INTEGER NOT NULL DEFAULT (nextval('topics')),
    message text NOT NULL DEFAULT '',
    status_id INTEGER NOT NULL,
    title VARCHAR(1024) NOT NULL DEFAULT '',
    update_id INTEGER NOT NULL DEFAULT (currval('updates'))
);


CREATE TRIGGER
    bi_func_new_task_1
BEFORE INSERT ON
    func_new_task
FOR EACH ROW
BEGIN

    SELECT debug(
        'TRIGGER bi_func_new_task_1',
        NEW.id,
        NEW.status_id,
        NEW.title,
        NEW.update_id
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
        'task',
        updates.mtime,
        updates.mtimetz,
        updates.mtime,
        updates.mtimetz,
        updates.lang,
        sha1_hex(
            'task',
            updates.author,
            updates.email,
            updates.lang,
            updates.message,
            updates.mtime,
            updates.mtimetz,
            NEW.title,
            topics.uuid
        )
    FROM
        updates
    INNER JOIN
        topics
    ON
        topics.id = NEW.status_id
    WHERE
        updates.id = NEW.update_id
    ;

    INSERT INTO tasks(
        id,
        status_id,
        title,
        update_id
    )
    VALUES(
        NEW.id,
        NEW.status_id,
        NEW.title,
        NEW.update_id
    );

    INSERT INTO
        task_updates(
            status_id,
            task_id,
            new,
            title,
            update_id
        )
    VALUES(
        NEW.status_id,
        NEW.id,
        1,
        NEW.title,
        NEW.update_id
    );

    SELECT RAISE(IGNORE);
END;