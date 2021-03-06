CREATE TABLE task_status_tomerge(
    task_status_id INTEGER NOT NULL UNIQUE,
    parent_id INTEGER DEFAULT 0,
    status INTEGER DEFAULT 0,
    rank INTEGER DEFAULT 0,
    def INTEGER DEFAULT 0,
    resolve INTEGER,
    FOREIGN KEY(task_status_id) REFERENCES task_status(id) ON DELETE CASCADE
);

CREATE TRIGGER
    task_status_tomerge_bu_5
BEFORE UPDATE OF
    resolve
ON
    task_status_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1
BEGIN

    SELECT debug(
        'TRIGGER task_status_tomerge_bu_5',
        OLD.task_status_id
    );

    UPDATE
        topics
    SET
        mtime = (
            SELECT
                changes.mtime
            FROM
                task_status_deltas
            INNER JOIN
                changes
            ON
                changes.id = task_status_deltas.change_id
            WHERE
                task_status_deltas.task_status_id = OLD.task_status_id
            ORDER BY
                changes.mtime DESC,
                changes.uuid
            LIMIT
                1
        )
    WHERE
        id = OLD.task_status_id
    ;

    DELETE FROM
        task_status_tomerge
    WHERE
        task_status_id = OLD.task_status_id
    ;

    SELECT RAISE(IGNORE);

END;

CREATE TRIGGER
    task_status_tomerge_bu_4
BEFORE UPDATE OF
    resolve
ON
    task_status_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1 AND
    OLD.def != 0
BEGIN

    SELECT debug(
        'TRIGGER task_status_tomerge_bu_4',
        OLD.task_status_id
    );

    UPDATE
        task_status
    SET
        def = 1
    WHERE
        id = (
            SELECT
                all_changes.task_status_id
            FROM
                task_status_deltas
            INNER JOIN
                task_status
            ON
                task_status.id = task_status_deltas.task_status_id
            INNER JOIN
                task_status AS all_status
            ON
                all_status.project_id = task_status.project_id
            INNER JOIN
                task_status_deltas AS all_changes
            ON
                all_changes.task_status_id = all_status.id AND
                all_changes.def = 1
            INNER JOIN
                changes
            ON
                changes.id = all_changes.change_id
            WHERE
                task_status_deltas.task_status_id = OLD.task_status_id
            ORDER BY
                changes.mtime DESC,
                changes.uuid
            LIMIT
                1
        )
    ;

END;

CREATE TRIGGER
    task_status_tomerge_bu_3
BEFORE UPDATE OF
    resolve
ON
    task_status_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1 AND
    OLD.rank != 0
BEGIN

    SELECT debug(
        'TRIGGER task_status_tomerge_bu_3',
        OLD.task_status_id
    );

    UPDATE
        task_status
    SET
        rank = (
            SELECT
                task_status_deltas.rank
            FROM
                task_status_deltas
            INNER JOIN
                changes
            ON
                changes.id = task_status_deltas.change_id
            WHERE
                task_status_deltas.task_status_id =
                    OLD.task_status_id AND
                task_status_deltas.rank IS NOT NULL
            ORDER BY
                changes.mtime DESC,
                changes.uuid
            LIMIT
                1
        )
    WHERE
        id = OLD.task_status_id
    ;

END;

CREATE TRIGGER
    task_status_tomerge_bu_1
BEFORE UPDATE OF
    resolve
ON
    task_status_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1 AND
    OLD.status != 0
BEGIN

    SELECT debug(
        'TRIGGER task_status_tomerge_bu_1',
        OLD.task_status_id
    );

    UPDATE
        task_status
    SET
        status = (
            SELECT
                task_status_deltas.status
            FROM
                task_status_deltas
            INNER JOIN
                changes
            ON
                changes.id = task_status_deltas.change_id
            WHERE
                task_status_deltas.task_status_id =
                    OLD.task_status_id AND
                task_status_deltas.status IS NOT NULL
            ORDER BY
                changes.mtime DESC,
                changes.uuid
            LIMIT
                1
        )
    WHERE
        id = OLD.task_status_id
    ;

END;

