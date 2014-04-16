CREATE TABLE task_updates (
    id INTEGER NOT NULL PRIMARY KEY DEFAULT (nextval('update_order')),
    update_id INTEGER NOT NULL,
    task_id INTEGER NOT NULL,
    new INTEGER,
    status_id INTEGER,
    title VARCHAR(1024),
    UNIQUE(update_id,task_id), -- one change per update
    FOREIGN KEY(update_id) REFERENCES updates(id) ON DELETE CASCADE,
    FOREIGN KEY(task_id) REFERENCES tasks(id) ON DELETE CASCADE,
    FOREIGN KEY(status_id) REFERENCES task_status(id)--,
--    UNIQUE (update_id,status_id) -- tasks FK to this
) WITHOUT ROWID;

CREATE TRIGGER
    ai_task_updates_2
AFTER INSERT ON
    task_updates
FOR EACH ROW WHEN
    NEW.status_id IS NOT NULL
BEGIN
    -- This catches the current update project for the task
    INSERT INTO
        project_related_updates(
            update_id,
            project_id
        )
    SELECT
        NEW.update_id,
        project_id
    FROM
        task_status
    WHERE
        id = NEW.status_id
    ;

END;

CREATE TRIGGER
    ai_task_updates_1
AFTER INSERT ON
    task_updates
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.update_id,
        NEW.task_id,
        NEW.status_id,
        NEW.title
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
                'task_update:' || x'0A'
                || 'task_uuid:' || COALESCE(topics.uuid, '') || x'0A'
                || 'status_uuid:' || COALESCE(status.uuid, '') || x'0A'
                || 'title:' || COALESCE(NEW.title, '') || x'0A'
            FROM
                topics
            LEFT JOIN
                topics as status
            ON
                status.id = NEW.status_id
            WHERE
                topics.id = NEW.task_id
        )
    WHERE
        update_id = NEW.update_id
    ;

    -- This catches the current project for the task
    INSERT INTO
        project_related_updates(
            update_id,
            project_id
        )
    SELECT
        NEW.update_id,
        task_status.project_id
    FROM
        tasks
    INNER JOIN
        task_status
    ON
        task_status.id = tasks.status_id
    WHERE
        tasks.id = NEW.task_id
    ;

    INSERT OR IGNORE INTO
        tasks_tomerge(task_id)
    VALUES
        (NEW.task_id)
    ;

    UPDATE
        tasks_tomerge
    SET
        status_id = status_id + (NEW.status_id IS NOT NULL),
        title    = title + (NEW.title IS NOT NULL)
    WHERE
        task_id = NEW.task_id
    ;

END;


CREATE TRIGGER
    ad_task_updates_1
AFTER DELETE ON
    task_updates
FOR EACH ROW
BEGIN

    SELECT debug(
        OLD.update_id,
        OLD.task_id,
        OLD.status_id,
        OLD.title
    );

    INSERT OR IGNORE INTO
        tasks_tomerge(task_id)
    VALUES
        (OLD.task_id)
    ;

    UPDATE
        tasks_tomerge
    SET
        status_id = status_id + (OLD.status_id IS NOT NULL),
        title    = title + (OLD.title IS NOT NULL)
    WHERE
        task_id = OLD.task_id
    ;

END;
