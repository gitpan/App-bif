CREATE TABLE projects_tomerge(
    project_id INTEGER NOT NULL UNIQUE,
    parent_id INTEGER DEFAULT 0,
    name INTEGER DEFAULT 0,
    title INTEGER DEFAULT 0,
    status_id INTEGER DEFAULT 0,
    hub_id INTEGER DEFAULT 0,
    resolve INTEGER,
    FOREIGN KEY(project_id) REFERENCES projects(id) ON DELETE CASCADE
);

-- TODO can these all be before update "OF resolve" triggers?

CREATE TRIGGER
    projects_tomerge_bu_5
BEFORE UPDATE OF
    resolve
ON
    projects_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1
BEGIN

    SELECT debug(
        'TRIGGER projects_tomerge_bu_5',
        OLD.project_id
    );

    UPDATE
        topics
    SET
        mtime = (
            SELECT
                updates.mtime
            FROM
                project_deltas
            INNER JOIN
                updates
            ON
                updates.id = project_deltas.update_id
            WHERE
                project_deltas.project_id = OLD.project_id
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
        projects_tomerge
    WHERE
        project_id = OLD.project_id
    ;

    SELECT RAISE(IGNORE);

END;

CREATE TRIGGER
    projects_tomerge_bu_4
BEFORE UPDATE OF
    resolve
ON
    projects_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1 AND
    OLD.parent_id != 0
BEGIN

    SELECT debug(
        'TRIGGER projects_tomerge_bu_4',
        OLD.project_id
    );

    UPDATE
        projects
    SET
        parent_id = (
            SELECT
                project_deltas.parent_id
            FROM
                project_deltas
            INNER JOIN
                updates
            ON
                updates.id = project_deltas.update_id
            WHERE
                project_deltas.project_id = OLD.project_id AND
                project_deltas.parent_id IS NOT NULL
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
    projects_tomerge_bu_3
BEFORE UPDATE OF
    resolve
ON
    projects_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1 AND
    OLD.name != 0
BEGIN

    SELECT debug(
        'TRIGGER projects_tomerge_bu_3',
        OLD.project_id
    );

    UPDATE
        projects
    SET
        name = (
            SELECT
                project_deltas.name
            FROM
                project_deltas
            INNER JOIN
                updates
            ON
                updates.id = project_deltas.update_id
            WHERE
                project_deltas.project_id = OLD.project_id AND
                project_deltas.name IS NOT NULL
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
    projects_tomerge_bu_2
BEFORE UPDATE OF
    resolve
ON
    projects_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1 AND
    OLD.title != 0
BEGIN

    SELECT debug(
        'TRIGGER projects_tomerge_bu_2',
        OLD.project_id
    );

    UPDATE
        projects
    SET
        title = (
            SELECT
                project_deltas.title
            FROM
                project_deltas
            INNER JOIN
                updates
            ON
                updates.id = project_deltas.update_id
            WHERE
                project_deltas.project_id = OLD.project_id AND
                project_deltas.title IS NOT NULL
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
    projects_tomerge_bu_1
BEFORE UPDATE OF
    resolve
ON
    projects_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1 AND
    OLD.status_id != 0
BEGIN

    SELECT debug(
        'TRIGGER projects_tomerge_bu_1',
        OLD.project_id
    );

    UPDATE
        projects
    SET
        status_id = (
            SELECT
                project_deltas.status_id
            FROM
                project_deltas
            INNER JOIN
                updates
            ON
                updates.id = project_deltas.update_id
            WHERE
                project_deltas.project_id = OLD.project_id AND
                project_deltas.status_id IS NOT NULL
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
    projects_tomerge_bu_0
BEFORE UPDATE OF
    resolve
ON
    projects_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1 AND
    OLD.hub_id != 0
BEGIN

    SELECT debug(
        'TRIGGER projects_tomerge_bu_0',
        OLD.project_id
    );

    UPDATE
        projects
    SET
        hub_id = (
            SELECT
                t.id
            FROM
                topics t
            WHERE
                t.uuid = (
                    SELECT
                        project_deltas.hub_uuid
                    FROM
                        project_deltas
                    INNER JOIN
                        updates
                    ON
                        updates.id = project_deltas.update_id
                    WHERE
                        project_deltas.project_id = OLD.project_id AND
                        project_deltas.hub_uuid IS NOT NULL
                    ORDER BY
                        updates.mtime DESC,
                        updates.uuid
                    LIMIT
                        1
                )
            )
    WHERE
        id = OLD.project_id
    ;

END;
