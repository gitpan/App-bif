CREATE TABLE project_mergers(
    project_id integer NOT NULL UNIQUE,
    parent_id integer DEFAULT 0,
    name integer DEFAULT 0,
    title integer DEFAULT 0,
    status_id integer DEFAULT 0,
    resolve integer,
    FOREIGN KEY(project_id) REFERENCES projects(id) ON DELETE CASCADE
);

-- TODO can these all be before update "OF resolve" triggers?

CREATE TRIGGER
    bu_project_mergers_5
BEFORE UPDATE OF
    resolve
ON
    project_mergers
FOR EACH ROW WHEN
    NEW.resolve = 1
BEGIN

    SELECT debug(
        'TRIGGER bu_project_mergers_5',
        OLD.project_id
    );

    UPDATE
        topics
    SET
        mtime = (
            SELECT
                updates.mtime
            FROM
                project_updates
            INNER JOIN
                updates
            ON
                updates.id = project_updates.update_id
            WHERE
                project_updates.project_id = OLD.project_id
            ORDER BY
                updates.mtime DESC,
                updates.uuid
            LIMIT
                1
        )
    WHERE
        id = OLD.project_id
    ;

    DELETE FROM
        project_mergers
    WHERE
        project_id = OLD.project_id
    ;

    SELECT RAISE(IGNORE);

END;

CREATE TRIGGER
    bu_project_mergers_4
BEFORE UPDATE OF
    resolve
ON
    project_mergers
FOR EACH ROW WHEN
    NEW.resolve = 1 AND
    OLD.parent_id != 0
BEGIN

    SELECT debug(
        'TRIGGER bu_project_mergers_4',
        OLD.project_id
    );

    UPDATE
        projects
    SET
        parent_id = (
            SELECT
                project_updates.parent_id
            FROM
                project_updates
            INNER JOIN
                updates
            ON
                updates.id = project_updates.update_id
            WHERE
                project_updates.project_id = OLD.project_id AND
                project_updates.parent_id IS NOT NULL
            ORDER BY
                updates.mtime DESC,
                updates.uuid
            LIMIT
                1
        )
    WHERE
        id = OLD.project_id
    ;

END;

CREATE TRIGGER
    bu_project_mergers_3
BEFORE UPDATE OF
    resolve
ON
    project_mergers
FOR EACH ROW WHEN
    NEW.resolve = 1 AND
    OLD.name != 0
BEGIN

    SELECT debug(
        'TRIGGER bu_project_mergers_3',
        OLD.project_id
    );

    UPDATE
        projects
    SET
        name = (
            SELECT
                project_updates.name
            FROM
                project_updates
            INNER JOIN
                updates
            ON
                updates.id = project_updates.update_id
            WHERE
                project_updates.project_id = OLD.project_id AND
                project_updates.name IS NOT NULL
            ORDER BY
                updates.mtime DESC,
                updates.uuid
            LIMIT
                1
        )
    WHERE
        id = OLD.project_id
    ;

END;

CREATE TRIGGER
    bu_project_mergers_2
BEFORE UPDATE OF
    resolve
ON
    project_mergers
FOR EACH ROW WHEN
    NEW.resolve = 1 AND
    OLD.title != 0
BEGIN

    SELECT debug(
        'TRIGGER bu_project_mergers_2',
        OLD.project_id
    );

    UPDATE
        projects
    SET
        title = (
            SELECT
                project_updates.title
            FROM
                project_updates
            INNER JOIN
                updates
            ON
                updates.id = project_updates.update_id
            WHERE
                project_updates.project_id = OLD.project_id AND
                project_updates.title IS NOT NULL
            ORDER BY
                updates.mtime DESC,
                updates.uuid
            LIMIT
                1
        )
    WHERE
        id = OLD.project_id
    ;

END;

CREATE TRIGGER
    bu_project_mergers_1
BEFORE UPDATE OF
    resolve
ON
    project_mergers
FOR EACH ROW WHEN
    NEW.resolve = 1 AND
    OLD.status_id != 0
BEGIN

    SELECT debug(
        'TRIGGER bu_project_mergers_1',
        OLD.project_id
    );

    UPDATE
        projects
    SET
        status_id = (
            SELECT
                project_updates.status_id
            FROM
                project_updates
            INNER JOIN
                updates
            ON
                updates.id = project_updates.update_id
            WHERE
                project_updates.project_id = OLD.project_id AND
                project_updates.status_id IS NOT NULL
            ORDER BY
                updates.mtime DESC,
                updates.uuid
            LIMIT
                1
        )
    WHERE
        id = OLD.project_id
    ;

END;
