CREATE TABLE tasks_tomerge(
    task_id INTEGER NOT NULL UNIQUE,
    parent_id INTEGER DEFAULT 0,
    task_status_id INTEGER DEFAULT 0,
    title INTEGER DEFAULT 0,
    resolve INTEGER,
    FOREIGN KEY(task_id) REFERENCES tasks(id) ON DELETE CASCADE
);

CREATE TRIGGER
    tasks_tomerge_bu_3
BEFORE UPDATE OF
    resolve
ON
    tasks_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1
BEGIN

    SELECT debug(
        'TRIGGER tasks_tomerge_bu_3',
        OLD.task_id
    );

    UPDATE
        topics
    SET
        mtime = (
            SELECT
                changes.mtime
            FROM
                task_deltas
            INNER JOIN
                changes
            ON
                changes.id = task_deltas.change_id
            WHERE
                task_deltas.task_id = OLD.task_id
            ORDER BY
                changes.mtime DESC,
                changes.uuid
            LIMIT
                1
        )
    WHERE
        id = OLD.task_id
    ;

    DELETE FROM
        tasks_tomerge
    WHERE
        task_id = OLD.task_id
    ;

    SELECT RAISE(IGNORE);

END;

CREATE TRIGGER
    tasks_tomerge_bu_2
BEFORE UPDATE OF
    resolve
ON
    tasks_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1 AND
    OLD.title != 0
BEGIN

    SELECT debug(
        'TRIGGER tasks_tomerge_bu_2',
        OLD.task_id
    );

    UPDATE
        tasks
    SET
        title = (
            SELECT
                task_deltas.title
            FROM
                task_deltas
            INNER JOIN
                changes
            ON
                changes.id = task_deltas.change_id
            WHERE
                task_deltas.task_id = OLD.task_id AND
                task_deltas.title IS NOT NULL
            ORDER BY
                changes.mtime DESC,
                changes.uuid
            LIMIT
                1
        )
    WHERE
        id = OLD.task_id
    ;

END;

CREATE TRIGGER
    tasks_tomerge_bu_1
BEFORE UPDATE OF
    resolve
ON
    tasks_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1 AND
    OLD.task_status_id != 0
BEGIN

    SELECT debug(
        'TRIGGER tasks_tomerge_bu_1',
        OLD.task_id
    );

    UPDATE
        tasks
    SET
        task_status_id = (
            SELECT
                task_deltas.task_status_id
            FROM
                task_deltas
            INNER JOIN
                changes
            ON
                changes.id = task_deltas.change_id
            WHERE
                task_deltas.task_id = OLD.task_id AND
                task_deltas.task_status_id IS NOT NULL
            ORDER BY
                changes.mtime DESC,
                changes.uuid
            LIMIT
                1
        ),
        change_id = (
            SELECT
                changes.id
            FROM
                task_deltas
            INNER JOIN
                changes
            ON
                changes.id = task_deltas.change_id
            WHERE
                task_deltas.task_id = OLD.task_id AND
                task_deltas.task_status_id IS NOT NULL
            ORDER BY
                changes.mtime DESC,
                changes.uuid
            LIMIT
                1
        )
    WHERE
        id = OLD.task_id
    ;

END;
