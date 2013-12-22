CREATE TABLE task_mergers(
    task_id integer NOT NULL UNIQUE,
    parent_id integer DEFAULT 0,
    status_id integer DEFAULT 0,
    title integer DEFAULT 0,
    resolve integer,
    FOREIGN KEY(task_id) REFERENCES tasks(id) ON DELETE CASCADE
);

CREATE TRIGGER
    bu_task_mergers_3
BEFORE UPDATE OF
    resolve
ON
    task_mergers
FOR EACH ROW WHEN
    NEW.resolve = 1
BEGIN

    SELECT debug(
        'TRIGGER bu_task_mergers_3',
        OLD.task_id
    );

    UPDATE
        topics
    SET
        mtime = (
            SELECT
                updates.mtime
            FROM
                task_updates
            INNER JOIN
                updates
            ON
                updates.id = task_updates.update_id
            WHERE
                task_updates.task_id = OLD.task_id
            ORDER BY
                updates.mtime DESC,
                updates.uuid
            LIMIT
                1
        )
    WHERE
        id = OLD.task_id
    ;

    DELETE FROM
        task_mergers
    WHERE
        task_id = OLD.task_id
    ;

    SELECT RAISE(IGNORE);

END;

CREATE TRIGGER
    bu_task_mergers_2
BEFORE UPDATE OF
    resolve
ON
    task_mergers
FOR EACH ROW WHEN
    NEW.resolve = 1 AND
    OLD.title != 0
BEGIN

    SELECT debug(
        'TRIGGER bu_task_mergers_2',
        OLD.task_id
    );

    UPDATE
        tasks
    SET
        title = (
            SELECT
                task_updates.title
            FROM
                task_updates
            INNER JOIN
                updates
            ON
                updates.id = task_updates.update_id
            WHERE
                task_updates.task_id = OLD.task_id AND
                task_updates.title IS NOT NULL
            ORDER BY
                updates.mtime DESC,
                updates.uuid
            LIMIT
                1
        )
    WHERE
        id = OLD.task_id
    ;

END;

CREATE TRIGGER
    bu_task_mergers_1
BEFORE UPDATE OF
    resolve
ON
    task_mergers
FOR EACH ROW WHEN
    NEW.resolve = 1 AND
    OLD.status_id != 0
BEGIN

    SELECT debug(
        'TRIGGER bu_task_mergers_1',
        OLD.task_id
    );

    UPDATE
        tasks
    SET
        status_id = (
            SELECT
                task_updates.status_id
            FROM
                task_updates
            INNER JOIN
                updates
            ON
                updates.id = task_updates.update_id
            WHERE
                task_updates.task_id = OLD.task_id AND
                task_updates.status_id IS NOT NULL
            ORDER BY
                updates.mtime DESC,
                updates.uuid
            LIMIT
                1
        ),
        update_id = (
            SELECT
                updates.id
            FROM
                task_updates
            INNER JOIN
                updates
            ON
                updates.id = task_updates.update_id
            WHERE
                task_updates.task_id = OLD.task_id AND
                task_updates.status_id IS NOT NULL
            ORDER BY
                updates.mtime DESC,
                updates.uuid
            LIMIT
                1
        )
    WHERE
        id = OLD.task_id
    ;

END;
