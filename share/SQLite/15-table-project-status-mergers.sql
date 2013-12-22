CREATE TABLE project_status_mergers(
    project_status_id integer NOT NULL UNIQUE,
    parent_id integer DEFAULT 0,
    status integer DEFAULT 0,
    rank integer DEFAULT 0,
    resolve integer,
    FOREIGN KEY(project_status_id) REFERENCES project_status(id)
        ON DELETE CASCADE
);

CREATE TRIGGER
    bu_project_status_mergers_4
BEFORE UPDATE OF
    resolve
ON
    project_status_mergers
FOR EACH ROW WHEN
    NEW.resolve = 1
BEGIN

    SELECT debug(
        'TRIGGER bu_project_status_mergers_4',
        OLD.project_status_id
    );

    UPDATE
        topics
    SET
        mtime = (
            SELECT
                updates.mtime
            FROM
                project_status_updates
            INNER JOIN
                updates
            ON
                updates.id = project_status_updates.update_id
            WHERE
                project_status_updates.project_status_id =
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
        project_status_mergers
    WHERE
        project_status_id = OLD.project_status_id
    ;

    SELECT RAISE(IGNORE);

END;

CREATE TRIGGER
    bu_project_status_mergers_3
BEFORE UPDATE OF
    resolve
ON
    project_status_mergers
FOR EACH ROW WHEN
    NEW.resolve = 1 AND
    OLD.rank != 0
BEGIN

    SELECT debug(
        'TRIGGER bu_project_status_mergers_3',
        OLD.project_status_id
    );

    UPDATE
        project_status
    SET
        rank = (
            SELECT
                project_status_updates.rank
            FROM
                project_status_updates
            INNER JOIN
                updates
            ON
                updates.id = project_status_updates.update_id
            WHERE
                project_status_updates.project_status_id =
                    OLD.project_status_id AND
                project_status_updates.rank IS NOT NULL
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
    bu_project_status_mergers_1
BEFORE UPDATE OF
    resolve
ON
    project_status_mergers
FOR EACH ROW WHEN
    NEW.resolve = 1 AND
    OLD.status != 0
BEGIN

    SELECT debug(
        'TRIGGER bu_project_status_mergers_1',
        OLD.project_status_id
    );


    UPDATE
        project_status
    SET
        status = (
            SELECT
                project_status_updates.status
            FROM
                project_status_updates
            INNER JOIN
                updates
            ON
                updates.id = project_status_updates.update_id
            WHERE
                project_status_updates.project_status_id =
                    OLD.project_status_id AND
                project_status_updates.status IS NOT NULL
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

