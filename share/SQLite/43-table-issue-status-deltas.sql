CREATE TABLE issue_status_deltas (
    id INTEGER NOT NULL PRIMARY KEY DEFAULT (nextval('update_order')),
    update_id INTEGER NOT NULL,
    issue_status_id INTEGER NOT NULL,
    new INTEGER,
    status VARCHAR,
    rank INTEGER,
    def INTEGER,
    UNIQUE(update_id,issue_status_id), -- one change per update
    FOREIGN KEY(update_id) REFERENCES updates(id) ON DELETE CASCADE
    FOREIGN KEY(issue_status_id) REFERENCES issue_status(id) ON DELETE CASCADE,
    CONSTRAINT def_constraint CHECK (
        def = 1 OR def IS NULL
    )
) WITHOUT ROWID;

CREATE TRIGGER
    issue_status_deltas_ai_1
AFTER INSERT ON
    issue_status_deltas
FOR EACH ROW
BEGIN
    
    SELECT debug(
        NEW.update_id,
        NEW.issue_status_id,
        NEW.status,
        NEW.rank,
        NEW.def
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
                'issue_status_delta:' || x'0A'
                || '  issue_status_uuid:' || COALESCE(topics.uuid, '') || x'0A'
                || '  status:' || COALESCE(NEW.status, '') || x'0A'
                || '  rank:' || COALESCE(NEW.rank, '') || x'0A'
                || '  def:' || COALESCE(NEW.def, '') || x'0A'
            FROM
                topics
            WHERE
                topics.id = NEW.issue_status_id
        )
    WHERE
        update_id = NEW.update_id
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
        issue_status
    WHERE
        id = NEW.issue_status_id
    ;

    INSERT OR IGNORE INTO
        issue_status_tomerge(issue_status_id)
    VALUES
        (NEW.issue_status_id)
    ;

    UPDATE
        issue_status_tomerge
    SET
        status = status + (NEW.status IS NOT NULL),
        rank   = rank + (NEW.rank IS NOT NULL),
        def    = def + (NEW.def IS NOT NULL)
    WHERE
        issue_status_id = NEW.issue_status_id
    ;

END;


CREATE TRIGGER
    issue_status_deltas_ad_1
AFTER DELETE ON
    issue_status_deltas
FOR EACH ROW
BEGIN

    SELECT debug(
        OLD.update_id,
        OLD.issue_status_id,
        OLD.status,
        OLD.rank,
        OLD.def
    );

    INSERT OR IGNORE INTO
        issue_status_tomerge(issue_status_id)
    VALUES
        (OLD.issue_status_id)
    ;

    UPDATE
        issue_status_tomerge
    SET
        status = status + (OLD.status IS NOT NULL),
        rank   = rank + (OLD.rank IS NOT NULL),
        def    = def + (OLD.def IS NOT NULL)
    WHERE
        issue_status_id = OLD.issue_status_id
    ;

END;