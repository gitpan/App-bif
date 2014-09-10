CREATE TABLE hub_repo_deltas (
    id INTEGER NOT NULL PRIMARY KEY DEFAULT (nextval('update_order')),
    update_id INTEGER NOT NULL,
    hub_id INTEGER,
    hub_repo_id INTEGER NOT NULL,
    new INTEGER,
    location VARCHAR,
    UNIQUE(update_id,hub_repo_id), -- one change per update
    FOREIGN KEY(update_id) REFERENCES updates(id) ON DELETE CASCADE
    FOREIGN KEY(hub_id) REFERENCES hubs(id) ON DELETE CASCADE
    FOREIGN KEY(hub_repo_id) REFERENCES hub_repos(id)
        ON DELETE CASCADE
) WITHOUT ROWID;

CREATE TRIGGER
    hub_repo_deltas_ai_1
AFTER INSERT ON
    hub_repo_deltas
FOR EACH ROW
BEGIN

    SELECT debug(
        'TRIGGER hub_repo_deltas_ai_1',
        NEW.id,
        NEW.update_id,
        NEW.hub_id,
        NEW.hub_repo_id,
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
                CASE WHEN
                    NEW.new
                THEN
                    '  - hub_repo:' || x'0A'
                ELSE
                    '  - hub_repo_delta:' || x'0A'
                    || '      hub_repo_uuid: ' || topics.uuid || x'0A'
                END
                || CASE WHEN
                    NEW.new
                THEN
                    '      hub_uuid: ' || h.uuid || x'0A'
                ELSE
                    ''
                END
                || '      location: ' || COALESCE(NEW.location, '~') || x'0A'
                || CASE WHEN
                    NEW.new
                THEN
                    '      topic_uuid: ' || topics.uuid || x'0A'
                ELSE
                    ''
                END
            FROM
                topics
            LEFT JOIN
                topics h
            ON
                h.id = NEW.hub_id
            WHERE
                topics.id = NEW.hub_repo_id
        )
    WHERE
        update_id = NEW.update_id
    ;

    INSERT OR IGNORE INTO
        hub_repos_tomerge(hub_repo_id)
    VALUES
        (NEW.hub_repo_id)
    ;

    INSERT INTO
        hub_related_updates(
            update_id,
            hub_id
        )
    VALUES(
        NEW.update_id,
        NEW.hub_id
    );

    UPDATE
        hub_repos_tomerge
    SET
        location = location + (NEW.location IS NOT NULL)
    WHERE
        hub_repo_id = NEW.hub_repo_id
    ;
END;


CREATE TRIGGER
    hub_repo_deltas_ad_1
AFTER DELETE ON
    hub_repo_deltas
FOR EACH ROW
BEGIN

    SELECT debug(
        'TRIGGER hub_repo_deltas_ad_1',
        OLD.update_id,
        OLD.hub_id,
        OLD.hub_repo_id,
        OLD.location
    );

    INSERT OR IGNORE INTO
        hub_repos_tomerge(hub_repo_id)
    VALUES
        (OLD.hub_repo_id)
    ;

    UPDATE
        hub_repos_tomerge
    SET
        location = location + (OLD.location IS NOT NULL)
    WHERE
        hub_repo_id = OLD.hub_repo_id
    ;

END;

