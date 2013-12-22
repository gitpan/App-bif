CREATE TABLE project_updates (
    update_id integer NOT NULL,
    update_order integer NOT NULL DEFAULT (nextval('update_order')),
    project_id integer NOT NULL,
    new integer,
    parent_id integer,
    name varchar(40),
    title varchar(1024),
    status_id integer,
--    UNIQUE(update_id,project_id), -- one change per update
    FOREIGN KEY(update_id) REFERENCES updates(id)
        ON DELETE CASCADE,
    FOREIGN KEY(project_id) REFERENCES projects(id)
        ON DELETE CASCADE
    FOREIGN KEY(status_id,project_id) REFERENCES project_status(id,project_id)
        ON DELETE CASCADE
);

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
        NEW.parent_id
    );

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

    INSERT INTO
        project_related_updates(
            update_id,
            project_id
        )
    VALUES(
        NEW.update_id,
        NEW.project_id
    );

    INSERT OR IGNORE INTO
        project_mergers(project_id) VALUES (NEW.project_id);

    UPDATE
        project_mergers
    SET
        parent_id = parent_id + (NEW.parent_id IS NOT NULL),
        name      = name + (NEW.name IS NOT NULL),
        title     = title + (NEW.title IS NOT NULL),
        status_id  = status_id + (NEW.status_id IS NOT NULL)
    WHERE
        project_id = NEW.project_id
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
        project_mergers(project_id) VALUES (OLD.project_id);

    UPDATE
        project_mergers
    SET
        parent_id = parent_id + (OLD.parent_id IS NOT NULL),
        name      = name + (OLD.name IS NOT NULL),
        title     = title + (OLD.title IS NOT NULL),
        status_id  = status_id + (OLD.status_id IS NOT NULL)
    WHERE
        project_id = OLD.project_id
    ;

END;
