CREATE TABLE project_status_tomerge(
    project_status_id INTEGER NOT NULL UNIQUE,
    parent_id INTEGER DEFAULT 0,
    status INTEGER DEFAULT 0,
    rank INTEGER DEFAULT 0,
    resolve INTEGER,
    FOREIGN KEY(project_status_id) REFERENCES project_status(id)
        ON DELETE CASCADE
);

CREATE TRIGGER
    project_status_tomerge_bu_4
BEFORE UPDATE OF
    resolve
ON
    project_status_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1
BEGIN

    SELECT debug(
        'TRIGGER project_status_tomerge_bu_4',
        OLD.project_status_id
    );

    UPDATE
        topics
    SET
        mtime = (
            SELECT
                updates.mtime
            FROM
                project_status_deltas
            INNER JOIN
                updates
            ON
                updates.id = project_status_deltas.update_id
            WHERE
                project_status_deltas.project_status_id =
                    OLD.project_status_id
            ORDER BY
                updates.mtime DESC,
                updates.uuid
            LIMIT
                1
        )
    WHERE
        id = OLD.project_status_id
    ;

    DELETE FROM
        project_status_tomerge
    WHERE
        project_status_id = OLD.project_status_id
    ;

    SELECT RAISE(IGNORE);

END;

CREATE TRIGGER
    project_status_tomerge_bu_3
BEFORE UPDATE OF
    resolve
ON
    project_status_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1 AND
    OLD.rank != 0
BEGIN

    SELECT debug(
        'TRIGGER project_status_tomerge_bu_3',
        OLD.project_status_id
    );

    UPDATE
        project_status
    SET
        rank = (
            SELECT
                project_status_deltas.rank
            FROM
                project_status_deltas
            INNER JOIN
                updates
            ON
                updates.id = project_status_deltas.update_id
            WHERE
                project_status_deltas.project_status_id =
                    OLD.project_status_id AND
                project_status_deltas.rank IS NOT NULL
            ORDER BY
                updates.mtime DESC,
                updates.uuid
            LIMIT
                1
        )
    WHERE
        id = OLD.project_status_id
    ;

END;

CREATE TRIGGER
    project_status_tomerge_bu_1
BEFORE UPDATE OF
    resolve
ON
    project_status_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1 AND
    OLD.status != 0
BEGIN

    SELECT debug(
        'TRIGGER project_status_tomerge_bu_1',
        OLD.project_status_id
    );


    UPDATE
        project_status
    SET
        status = (
            SELECT
                project_status_deltas.status
            FROM
                project_status_deltas
            INNER JOIN
                updates
            ON
                updates.id = project_status_deltas.update_id
            WHERE
                project_status_deltas.project_status_id =
                    OLD.project_status_id AND
                project_status_deltas.status IS NOT NULL
            ORDER BY
                updates.mtime DESC,
                updates.uuid
            LIMIT
                1
        )
    WHERE
        id = OLD.project_status_id
    ;

END;

