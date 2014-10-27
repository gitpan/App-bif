CREATE TABLE project_deltas (
    id INT NOT NULL PRIMARY KEY DEFAULT (nextval('deltas')),
    change_id INTEGER NOT NULL,
    project_id INTEGER NOT NULL,
    new INTEGER,
    parent_id INTEGER,
    name VARCHAR(40),
    title VARCHAR(1024),
    project_status_id INTEGER,
    hub_id VARCHAR,
    FOREIGN KEY(project_status_id,project_id)
        REFERENCES project_status(id,project_id)
        ON DELETE CASCADE,
    FOREIGN KEY(hub_id) REFERENCES hubs(id)
        ON DELETE CASCADE
);

CREATE TRIGGER
    project_deltas_ai_1
AFTER INSERT ON
    project_deltas
FOR EACH ROW
BEGIN

    SELECT debug(
        'TRIGGER project_deltas_ai_1',
        NEW.project_id,
        NEW.name,
        NEW.title,
        NEW.project_status_id,
        NEW.parent_id,
        NEW.hub_id
    );

    UPDATE
        changes
    SET
        ucount = ucount + 1
    WHERE
        id = NEW.change_id
    ;

    UPDATE
        topics
    SET
        last_change_id = NEW.change_id
    WHERE
        id = NEW.project_id
    ;

    UPDATE
        changes_pending
    SET
        terms = terms || (
            SELECT
                '-' || x'0A'
                || CASE WHEN
                    NEW.new
                THEN
                    '  _: project' || x'0A'
                ELSE
                    '  _: project_delta' || x'0A'
                || '  hub_uuid: ' || COALESCE(hubs.uuid, '~') || x'0A'
                END
                || '  name: ' || COALESCE(NEW.name, '~') || x'0A'
                || '  parent_uuid: '
                || COALESCE(parent.uuid, '~') || x'0A'
                || CASE WHEN
                    NEW.new
                THEN
                    ''
                ELSE
                    '  project_status_uuid: '
                    || COALESCE(status.uuid, '~') || x'0A'
                    ||'  project_uuid: ' || topics.uuid || x'0A'
                END
                || '  title: ' || COALESCE(NEW.title, '~') || x'0A'
                || CASE WHEN
                    NEW.new
                THEN
                    '  topic_uuid: ' || topics.uuid || x'0A'
                ELSE
                    ''
                END
            FROM
                topics
            LEFT JOIN
                topics AS parent
            ON
                parent.id = NEW.parent_id
            LEFT JOIN
                topics AS status
            ON
                status.id = NEW.project_status_id
            LEFT JOIN
                topics AS hubs
            ON
                hubs.id = NEW.hub_id
            WHERE
                topics.id = NEW.project_id
        )
    WHERE
        change_id = NEW.change_id
    ;

    INSERT OR IGNORE INTO
        projects_tomerge(project_id) VALUES (NEW.project_id);

    UPDATE
        projects_tomerge
    SET
        parent_id = parent_id + (NEW.parent_id IS NOT NULL),
        name      = name + (NEW.name IS NOT NULL),
        title     = title + (NEW.title IS NOT NULL),
        project_status_id = project_status_id +
            (NEW.project_status_id IS NOT NULL),
        hub_id   = hub_id + (NEW.hub_id IS NOT NULL)
    WHERE
        project_id = NEW.project_id
    ;

    INSERT INTO
        project_changes(
            change_id,
            project_id
        )
    VALUES(
        NEW.change_id,
        NEW.project_id
    );

END;


CREATE TRIGGER
    project_deltas_ad_1
AFTER DELETE ON
    project_deltas
FOR EACH ROW
BEGIN

    SELECT debug(
        'TRIGGER project_deltas_ad_1',
        OLD.project_id,
        OLD.name,
        OLD.project_status_id,
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
        project_status_id = project_status_id
            + (OLD.project_status_id IS NOT NULL),
        hub_id   = hub_id + (OLD.hub_id IS NOT NULL)
    WHERE
        project_id = OLD.project_id
    ;

END;
