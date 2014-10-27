CREATE TABLE hub_repo_deltas (
    id INT NOT NULL PRIMARY KEY DEFAULT (nextval('deltas')),
    change_id INTEGER NOT NULL,
    hub_id INTEGER,
    hub_repo_id INTEGER NOT NULL,
    new INTEGER,
    location VARCHAR,
    UNIQUE(change_id,hub_repo_id), -- one change per change
    FOREIGN KEY(change_id) REFERENCES changes(id) ON DELETE CASCADE
    FOREIGN KEY(hub_id) REFERENCES hubs(id) ON DELETE CASCADE
    FOREIGN KEY(hub_repo_id) REFERENCES hub_repos(id)
        ON DELETE CASCADE
);

CREATE TRIGGER
    hub_repo_deltas_ai_1
AFTER INSERT ON
    hub_repo_deltas
FOR EACH ROW
BEGIN

    SELECT debug(
        'TRIGGER hub_repo_deltas_ai_1',
        NEW.id,
        NEW.change_id,
        NEW.hub_id,
        NEW.hub_repo_id,
        NEW.new,
        NEW.location
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
        id = NEW.hub_repo_id
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
                    '  _: hub_repo' || x'0A'
                ELSE
                    '  _: hub_repo_delta' || x'0A'
                    || '  hub_repo_uuid: ' || topics.uuid || x'0A'
                END
                || CASE WHEN
                    NEW.new
                THEN
                    '  hub_uuid: ' || h.uuid || x'0A'
                ELSE
                    ''
                END
                || '  location: ' || COALESCE(NEW.location, '~') || x'0A'
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
                topics h
            ON
                h.id = NEW.hub_id
            WHERE
                topics.id = NEW.hub_repo_id
        )
    WHERE
        change_id = NEW.change_id
    ;

    INSERT OR IGNORE INTO
        hub_repos_tomerge(hub_repo_id)
    VALUES
        (NEW.hub_repo_id)
    ;

    INSERT INTO
        hub_related_changes(
            change_id,
            hub_id
        )
    VALUES(
        NEW.change_id,
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
        OLD.change_id,
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

