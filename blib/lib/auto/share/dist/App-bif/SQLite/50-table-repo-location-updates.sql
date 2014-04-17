CREATE TABLE repo_location_updates (
    id INTEGER NOT NULL PRIMARY KEY DEFAULT (nextval('update_order')),
    update_id INTEGER NOT NULL,
    repo_location_id INTEGER NOT NULL,
    new INTEGER,
    location VARCHAR,
    UNIQUE(update_id,repo_location_id), -- one change per update
    FOREIGN KEY(update_id) REFERENCES updates(id) ON DELETE CASCADE
    FOREIGN KEY(repo_location_id) REFERENCES repo_locations(id)
        ON DELETE CASCADE
) WITHOUT ROWID;

CREATE TRIGGER
    ai_repo_location_updates_1
AFTER INSERT ON
    repo_location_updates
FOR EACH ROW
BEGIN

    SELECT debug(
        'TRIGGER ai_repo_location_updates_1',
        NEW.id,
        NEW.update_id,
        NEW.repo_location_id,
        NEW.location
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
                'repo_location_update:' || x'0A'
                || '  repo_location_uuid:' || COALESCE(topics.uuid, '') || x'0A'
                || '  location:' || COALESCE(NEW.location, '') || x'0A'
            FROM
                topics
            WHERE
                topics.id = NEW.repo_location_id
        )
    WHERE
        update_id = NEW.update_id
    ;

    INSERT OR IGNORE INTO
        repo_locations_tomerge(repo_location_id)
    VALUES
        (NEW.repo_location_id)
    ;

    INSERT INTO
        repo_related_updates(
            update_id,
            repo_id
        )
    SELECT
        NEW.update_id,
        rl.repo_id
    FROM
        repo_locations rl
    WHERE
        id = NEW.repo_location_id
    ;

    UPDATE
        repo_locations_tomerge
    SET
        location = location + (NEW.location IS NOT NULL)
    WHERE
        repo_location_id = NEW.repo_location_id
    ;
END;


CREATE TRIGGER
    ad_repo_location_updates_1
AFTER DELETE ON
    repo_location_updates
FOR EACH ROW
BEGIN

    SELECT debug(
        'TRIGGER ad_repo_location_updates_1',
        OLD.update_id,
        OLD.repo_location_id,
        OLD.location
    );

    INSERT OR IGNORE INTO
        repo_locations_tomerge(repo_location_id)
    VALUES
        (OLD.repo_location_id)
    ;

    UPDATE
        repo_locations_tomerge
    SET
        location = location + (OLD.location IS NOT NULL)
    WHERE
        repo_location_id = OLD.repo_location_id
    ;

END;

