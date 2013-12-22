CREATE TABLE task_status_updates (
    update_id integer NOT NULL,
    update_order integer NOT NULL DEFAULT (nextval('update_order')),
    task_status_id integer NOT NULL,
    new integer,
    status varchar,
    rank integer,
    def integer,
    UNIQUE(update_id,task_status_id), -- one change per update
    FOREIGN KEY(update_id) REFERENCES updates(id) ON DELETE CASCADE
    FOREIGN KEY(task_status_id) REFERENCES task_status(id) ON DELETE CASCADE
);

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

    INSERT OR IGNORE INTO
        task_status_mergers(task_status_id)
    VALUES
        (NEW.task_status_id)
    ;

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
        id = NEW.task_status_id
    ;

    UPDATE
        task_status_mergers
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
        task_status_mergers(task_status_id)
    VALUES
        (OLD.task_status_id)
    ;

    UPDATE
        task_status_mergers
    SET
        status = status + (OLD.status IS NOT NULL),
        rank   = rank + (OLD.rank IS NOT NULL),
        def    = def + (OLD.def IS NOT NULL)
    WHERE
        task_status_id = OLD.task_status_id
    ;

END;
