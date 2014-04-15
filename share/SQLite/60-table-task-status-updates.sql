CREATE TABLE task_status_updates (
    id INTEGER NOT NULL PRIMARY KEY DEFAULT (nextval('update_order')),
    update_id INTEGER NOT NULL,
    task_status_id INTEGER NOT NULL,
    new INTEGER,
    status VARCHAR,
    rank INTEGER,
    def INTEGER,
    UNIQUE(update_id,task_status_id), -- one change per update
    FOREIGN KEY(update_id) REFERENCES updates(id) ON DELETE CASCADE
    FOREIGN KEY(task_status_id) REFERENCES task_status(id) ON DELETE CASCADE
) WITHOUT ROWID;

CREATE TRIGGER
    ai_task_status_updates_1
AFTER INSERT ON
    task_status_updates
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.update_id,
        NEW.task_status_id,
        NEW.status,
        NEW.rank,
        NEW.def
    );

    UPDATE
        updates_pending
    SET
        terms = terms || (
            SELECT
                'task_status_update:' || x'0A'
                || 'task_status_uuid:' || COALESCE(topics.uuid, '') || x'0A'
                || 'status:' || COALESCE(NEW.status, '') || x'0A'
                || 'rank:' || COALESCE(NEW.rank, '') || x'0A'
                || 'def:' || COALESCE(NEW.rank, '') || x'0A'
            FROM
                topics
            WHERE
                topics.id = NEW.task_status_id
        )
    WHERE
        update_id = NEW.update_id
    ;

    INSERT INTO
        project_related_updates(
            update_id,
            project_id,
            project_only
        )
    SELECT
        NEW.update_id,
        project_id,
        1
    FROM
        task_status
    WHERE
        id = NEW.task_status_id
    ;

    INSERT OR IGNORE INTO
        task_status_tomerge(task_status_id)
    VALUES
        (NEW.task_status_id)
    ;

    UPDATE
        task_status_tomerge
    SET
        status = status + (NEW.status IS NOT NULL),
        rank   = rank + (NEW.rank IS NOT NULL),
        def    = def + (NEW.def IS NOT NULL)
    WHERE
        task_status_id = NEW.task_status_id
    ;

END;


CREATE TRIGGER
    ad_task_status_updates_1
AFTER DELETE ON
    task_status_updates
FOR EACH ROW
BEGIN

    SELECT debug(
        OLD.update_id,
        OLD.task_status_id,
        OLD.status,
        OLD.rank,
        OLD.def
    );

    INSERT OR IGNORE INTO
        task_status_tomerge(task_status_id)
    VALUES
        (OLD.task_status_id)
    ;

    UPDATE
        task_status_tomerge
    SET
        status = status + (OLD.status IS NOT NULL),
        rank   = rank + (OLD.rank IS NOT NULL),
        def    = def + (OLD.def IS NOT NULL)
    WHERE
        task_status_id = OLD.task_status_id
    ;

END;
