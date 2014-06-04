CREATE TABLE project_status_deltas (
    id INTEGER NOT NULL PRIMARY KEY DEFAULT (nextval('update_order')),
    update_id INTEGER NOT NULL,
    project_status_id INTEGER NOT NULL,
    new INTEGER,
    status VARCHAR,
    rank INTEGER,
    UNIQUE(update_id,project_status_id), -- one change per update
    FOREIGN KEY(update_id) REFERENCES updates(id) ON DELETE CASCADE
    FOREIGN KEY(project_status_id) REFERENCES project_status(id)
        ON DELETE CASCADE
) WITHOUT ROWID;

CREATE TRIGGER
    project_status_deltas_ai_1
AFTER INSERT ON
    project_status_deltas
FOR EACH ROW
BEGIN

    SELECT debug(
        'TRIGGER project_status_deltas_ai_1',
        NEW.id,
        NEW.update_id,
        NEW.project_status_id,
        NEW.status,
        NEW.rank
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
                'project_status_delta:' || x'0A'
                || '  project_status_uuid:' || COALESCE(topics.uuid, '')|| x'0A'
                || '  status:' || COALESCE(NEW.status, '') || x'0A'
                || '  rank:' || COALESCE(NEW.rank, '') || x'0A'
            FROM
                topics
            WHERE
                topics.id = NEW.project_status_id
        )
    WHERE
        update_id = NEW.update_id
    ;

    INSERT OR IGNORE INTO
        project_status_tomerge(project_status_id)
    VALUES
        (NEW.project_status_id)
    ;

    INSERT INTO
        project_only_updates(
            update_id,
            project_id
        )
    SELECT
        NEW.update_id,
        project_id
    FROM
        project_status
    WHERE
        id = NEW.project_status_id
    ;

    UPDATE
        project_status_tomerge
    SET
        status = status + (NEW.status IS NOT NULL),
        rank   = rank + (NEW.rank IS NOT NULL)
    WHERE
        project_status_id = NEW.project_status_id
    ;

END;


CREATE TRIGGER
    project_status_deltas_ad_1
AFTER DELETE ON
    project_status_deltas
FOR EACH ROW
BEGIN

    SELECT debug(
        'TRIGGER project_status_deltas_ad_1',
        OLD.update_id,
        OLD.project_status_id,
        OLD.status,
        OLD.rank
    );

    INSERT OR IGNORE INTO
        project_status_tomerge(project_status_id)
    VALUES
        (OLD.project_status_id)
    ;

    UPDATE
        project_status_tomerge
    SET
        status = status + (OLD.status IS NOT NULL),
        rank   = rank + (OLD.rank IS NOT NULL)
    WHERE
        project_status_id = OLD.project_status_id
    ;

END;
