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
    bu_projects_tomerge_5
BEFORE UPDATE OF
    resolve
ON
    projects_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1
BEGIN

    SELECT debug(
        'TRIGGER bu_projects_tomerge_5',
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
        projects_tomerge
    WHERE
        project_id = OLD.project_id
    ;

    SELECT RAISE(IGNORE);

END;

CREATE TRIGGER
    bu_projects_tomerge_4
BEFORE UPDATE OF
    resolve
ON
    projects_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1 AND
    OLD.parent_id != 0
BEGIN

    SELECT debug(
        'TRIGGER bu_projects_tomerge_4',
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
    bu_projects_tomerge_3
BEFORE UPDATE OF
    resolve
ON
    projects_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1 AND
    OLD.name != 0
BEGIN

    SELECT debug(
        'TRIGGER bu_projects_tomerge_3',
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
    bu_projects_tomerge_2
BEFORE UPDATE OF
    resolve
ON
    projects_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1 AND
    OLD.title != 0
BEGIN

    SELECT debug(
        'TRIGGER bu_projects_tomerge_2',
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
    bu_projects_tomerge_1
BEFORE UPDATE OF
    resolve
ON
    projects_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1 AND
    OLD.status_id != 0
BEGIN

    SELECT debug(
        'TRIGGER bu_projects_tomerge_1',
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

CREATE TRIGGER
    bu_projects_tomerge_0
BEFORE UPDATE OF
    resolve
ON
    projects_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1 AND
    OLD.hub_id != 0
BEGIN

    SELECT debug(
        'TRIGGER bu_projects_tomerge_0',
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
                        project_updates.hub_uuid
                    FROM
                        project_updates
                    INNER JOIN
                        updates
                    ON
                        updates.id = project_updates.update_id
                    WHERE
                        project_updates.project_id = OLD.project_id AND
                        project_updates.hub_uuid IS NOT NULL
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
