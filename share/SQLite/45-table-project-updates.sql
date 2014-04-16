CREATE TABLE project_updates (
    id INTEGER NOT NULL PRIMARY KEY DEFAULT (nextval('update_order')),
    update_id INTEGER NOT NULL,
    project_id INTEGER NOT NULL,
    new INTEGER,
    parent_id INTEGER,
    name VARCHAR(40),
    title VARCHAR(1024),
    status_id INTEGER,
    repo_uuid VARCHAR,
--    UNIQUE(update_id,project_id), -- one change per update
    FOREIGN KEY(update_id) REFERENCES updates(id)
        ON DELETE CASCADE,
    FOREIGN KEY(project_id) REFERENCES projects(id)
        ON DELETE CASCADE
    FOREIGN KEY(status_id,project_id) REFERENCES project_status(id,project_id)
        ON DELETE CASCADE
) WITHOUT ROWID;

CREATE TRIGGER
    ai_project_updates_1
AFTER INSERT ON
    project_updates
FOR EACH ROW
BEGIN

    SELECT debug(
        'TRIGGER ai_project_updates_1',
        NEW.project_id,
        NEW.name,
        NEW.title,
        NEW.status_id,
        NEW.parent_id,
        NEW.repo_uuid
    );

    UPDATE
        updates
    SET
        ucount = ucount + 1
    WHERE
        id = NEW.update_id
    ;

    UPDATE
        updates_pending
    SET
        terms = terms || (
            SELECT
                'project_update:' || x'0A'
                || 'project_uuid:' || COALESCE(project.uuid, '') || x'0A'
                || 'parent_uuid:' || COALESCE(parent.uuid, '') || x'0A'
                || 'name:' || COALESCE(NEW.name, '') || x'0A'
                || 'title:' || COALESCE(NEW.title, '') || x'0A'
                || 'status_uuid:' || COALESCE(status.uuid, '') || x'0A'
                || 'repo_uuid:' || COALESCE(NEW.repo_uuid, '') || x'0A'
            FROM
                (SELECT 1)
            INNER JOIN
                topics AS project
            ON
                project.id = NEW.project_id
            LEFT JOIN
                topics AS parent
            ON
                parent.id = NEW.parent_id
            LEFT JOIN
                topics AS status
            ON
                status.id = NEW.status_id
        )
    WHERE
        update_id = NEW.update_id
    ;

    INSERT OR IGNORE INTO
        projects_tomerge(project_id) VALUES (NEW.project_id);

    UPDATE
        projects_tomerge
    SET
        parent_id = parent_id + (NEW.parent_id IS NOT NULL),
        name      = name + (NEW.name IS NOT NULL),
        title     = title + (NEW.title IS NOT NULL),
        status_id = status_id + (NEW.status_id IS NOT NULL),
        repo_id   = repo_id + (NEW.repo_uuid IS NOT NULL)
    WHERE
        project_id = NEW.project_id
    ;

    INSERT INTO
        project_related_updates(
            update_id,
            project_id,
            project_only
        )
    VALUES(
        NEW.update_id,
        NEW.project_id,
        1
    );

    /*
        In the event that a project is exported to a hub, create a
        matching set of repo-related updates from the project-(only)-
        related updates.

        TODO - do the reverse when NEW.repo_id is set to null, or
        rather set to something else.
    */

    INSERT INTO
        repo_related_updates(
            repo_id,
            update_id
        )
    SELECT
        t.id,
        pru.update_id
    FROM
        topics t
    INNER JOIN
        project_related_updates pru
    ON
        pru.project_id = NEW.project_id AND
        pru.project_only = 1
    WHERE
        t.uuid = NEW.repo_uuid
    ;

END;


CREATE TRIGGER
    ad_project_updates_1
AFTER DELETE ON
    project_updates
FOR EACH ROW
BEGIN

    SELECT debug(
        'TRIGGER ad_project_updates_1',
        OLD.project_id,
        OLD.name,
        OLD.status_id,
        OLD.parent_id
    );

    INSERT OR IGNORE INTO
        projects_tomerge(project_id) VALUES (OLD.project_id);

    UPDATE
        projects_tomerge
    SET
        parent_id = parent_id + (OLD.parent_id IS NOT NULL),
        name      = name + (OLD.name IS NOT NULL),
        title     = title + (OLD.title IS NOT NULL),
        status_id = status_id + (OLD.status_id IS NOT NULL),
        repo_id   = repo_id + (OLD.repo_uuid IS NOT NULL)
    WHERE
        project_id = OLD.project_id
    ;

END;
