CREATE TABLE task_status_mergers(
    task_status_id integer NOT NULL UNIQUE,
    parent_id integer DEFAULT 0,
    status integer DEFAULT 0,
    rank integer DEFAULT 0,
    def integer DEFAULT 0,
    resolve integer,
    FOREIGN KEY(task_status_id) REFERENCES task_status(id) ON DELETE CASCADE
);

CREATE TRIGGER
    bu_task_status_mergers_5
BEFORE UPDATE OF
    resolve
ON
    task_status_mergers
FOR EACH ROW WHEN
    NEW.resolve = 1
BEGIN

    SELECT debug(
        'TRIGGER bu_task_status_mergers_5',
        OLD.task_status_id
    );

    UPDATE
        topics
    SET
        mtime = (
            SELECT
                updates.mtime
            FROM
                task_status_updates
            INNER JOIN
                updates
            ON
                updates.id = task_status_updates.update_id
            WHERE
                task_status_updates.task_status_id = OLD.task_status_id
            ORDER BY
                updates.mtime DESC,
                updates.uuid
            LIMIT
                1
        )
    WHERE
        id = OLD.task_status_id
    ;

    DELETE FROM
        task_status_mergers
    WHERE
        task_status_id = OLD.task_status_id
    ;

    SELECT RAISE(IGNORE);

END;

CREATE TRIGGER
    bu_task_status_mergers_4
BEFORE UPDATE OF
    resolve
ON
    task_status_mergers
FOR EACH ROW WHEN
    NEW.resolve = 1 AND
    OLD.def != 0
BEGIN

    SELECT debug(
        'TRIGGER bu_task_status_mergers_4',
        OLD.task_status_id
    );

    UPDATE
        task_status
    SET
        def = 1
    WHERE
        id = (
            SELECT
                all_updates.task_status_id
            FROM
                task_status_updates
            INNER JOIN
                task_status
            ON
                task_status.id = task_status_updates.task_status_id
            INNER JOIN
                task_status AS all_status
            ON
                all_status.project_id = task_status.project_id
            INNER JOIN
                task_status_updates AS all_updates
            ON
                all_updates.task_status_id = all_status.id AND
                all_updates.def = 1
            INNER JOIN
                updates
            ON
                updates.id = all_updates.update_id
            WHERE
                task_status_updates.task_status_id = OLD.task_status_id
            ORDER BY
                updates.mtime DESC,
                updates.uuid
            LIMIT
                1
        )
    ;

END;

CREATE TRIGGER
    bu_task_status_mergers_3
BEFORE UPDATE OF
    resolve
ON
    task_status_mergers
FOR EACH ROW WHEN
    NEW.resolve = 1 AND
    OLD.rank != 0
BEGIN

    SELECT debug(
        'TRIGGER bu_task_status_mergers_3',
        OLD.task_status_id
    );

    UPDATE
        task_status
    SET
        rank = (
            SELECT
                task_status_updates.rank
            FROM
                task_status_updates
            INNER JOIN
                updates
            ON
                updates.id = task_status_updates.update_id
            WHERE
                task_status_updates.task_status_id =
                    OLD.task_status_id AND
                task_status_updates.rank IS NOT NULL
            ORDER BY
                updates.mtime DESC,
                updates.uuid
            LIMIT
                1
        )
    WHERE
        id = OLD.task_status_id
    ;

END;

CREATE TRIGGER
    bu_task_status_mergers_1
BEFORE UPDATE OF
    resolve
ON
    task_status_mergers
FOR EACH ROW WHEN
    NEW.resolve = 1 AND
    OLD.status != 0
BEGIN

    SELECT debug(
        'TRIGGER bu_task_status_mergers_1',
        OLD.task_status_id
    );

    UPDATE
        task_status
    SET
        status = (
            SELECT
                task_status_updates.status
            FROM
                task_status_updates
            INNER JOIN
                updates
            ON
                updates.id = task_status_updates.update_id
            WHERE
                task_status_updates.task_status_id =
                    OLD.task_status_id AND
                task_status_updates.status IS NOT NULL
            ORDER BY
                updates.mtime DESC,
                updates.uuid
            LIMIT
                1
        )
    WHERE
        id = OLD.task_status_id
    ;

END;

