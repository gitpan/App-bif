CREATE TABLE repo_updates (
    id INTEGER NOT NULL PRIMARY KEY DEFAULT (nextval('update_order')),
    update_id INTEGER NOT NULL DEFAULT NULL,
    repo_id INTEGER NOT NULL,
    related_update_uuid VARCHAR,
    new INTEGER,
    default_location_id INTEGER,
    FOREIGN KEY(update_id) REFERENCES updates(id) ON DELETE CASCADE,
    FOREIGN KEY(repo_id) REFERENCES repos(id) ON DELETE CASCADE,
    FOREIGN KEY(default_location_id) REFERENCES repo_locations(id)
        ON DELETE CASCADE
) WITHOUT ROWID;

CREATE TRIGGER
    ai_repo_updates_1
AFTER INSERT ON
    repo_updates
FOR EACH ROW
BEGIN

    SELECT debug(
        'TRIGGER ai_repo_updates_1',
        NEW.update_id,
        NEW.related_update_uuid,
        NEW.repo_id,
        NEW.default_location_id
    );

    UPDATE
        updates_pending
    SET
        terms = terms || (
            SELECT
                'repo_update:' || x'0A'
                || 'repo_uuid:' || COALESCE(topics.uuid, '') || x'0A'
                || 'related_update_uuid:'
                    || COALESCE(NEW.related_update_uuid, '') || x'0A'
                || 'default_location_uuid:' || COALESCE(location.uuid, '')
                    || x'0A'
            FROM
                topics
            LEFT JOIN
                topics AS location
            ON
                location.id = NEW.default_location_id
            WHERE
                topics.id = NEW.repo_id
        )
    WHERE
        update_id = NEW.update_id
    ;

    INSERT INTO
        repo_related_updates(
            update_id,
            repo_id
        )
    VALUES (
        NEW.update_id,
        NEW.repo_id
    );


    INSERT OR IGNORE INTO
        repo_tomerge(repo_id) VALUES (NEW.repo_id);

    UPDATE
        repo_tomerge
    SET
        default_location_id = default_location_id +
        (NEW.default_location_id IS NOT NULL)
    WHERE
        repo_id = NEW.repo_id
    ;

END;

CREATE TRIGGER
    ad_repo_updates_1
AFTER DELETE ON
    repo_updates
FOR EACH ROW
BEGIN

    SELECT debug(
        'TRIGGER ad_repo_updates_1',
        OLD.repo_id,
        OLD.default_location_id
    );

    INSERT OR IGNORE INTO
        repo_tomerge(repo_id) VALUES (OLD.repo_id);

    UPDATE
        repo_tomerge
    SET
        default_location_id = default_location_id +
        (OLD.default_location_id IS NOT NULL)
    WHERE
        repo_id = OLD.repo_id
    ;

END;

