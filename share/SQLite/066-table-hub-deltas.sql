CREATE TABLE hub_deltas (
    id INT NOT NULL PRIMARY KEY DEFAULT (nextval('deltas')),
    change_id INTEGER NOT NULL,
    hub_id INTEGER NOT NULL,
    name VARCHAR(128),
    new INTEGER,
    FOREIGN KEY(change_id) REFERENCES changes(id) ON DELETE CASCADE,
    FOREIGN KEY(hub_id) REFERENCES hubs(id) ON DELETE CASCADE
);

CREATE TRIGGER
    hub_deltas_ai_1
AFTER INSERT ON
    hub_deltas
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.change_id,
        NEW.hub_id,
        NEW.name
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
        id = NEW.hub_id
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
                    '  _: hub' || x'0A'
                ELSE
                    '  _: hub_delta' || x'0A'
                    || '  hub_uuid: ' || topics.uuid || x'0A'
                END
                || '  name: ' || COALESCE(NEW.name, '~') || x'0A'
                || CASE WHEN
                    NEW.new
                THEN
                    '  topic_uuid: ' || topics.uuid || x'0A'
                ELSE
                    ''
                END
            FROM
                topics
            WHERE
                topics.id = NEW.hub_id
        )
    WHERE
        change_id = NEW.change_id
    ;

    INSERT INTO
        hub_related_changes(
            change_id,
            hub_id
        )
    VALUES (
        NEW.change_id,
        NEW.hub_id
    );

    INSERT OR IGNORE INTO
        hubs_tomerge(hub_id) VALUES (NEW.hub_id);

    UPDATE
        hubs_tomerge
    SET
        name = name + (NEW.name IS NOT NULL)
    WHERE
        hub_id = NEW.hub_id
    ;

END;

CREATE TRIGGER
    hub_deltas_ad_1
AFTER DELETE ON
    hub_deltas
FOR EACH ROW
BEGIN

    SELECT debug(
        'TRIGGER hub_deltas_ad_1',
        OLD.hub_id
    );

    INSERT OR IGNORE INTO
        hubs_tomerge(hub_id) VALUES (OLD.hub_id);

    UPDATE
        hubs_tomerge
    SET
        name = name + (OLD.name IS NOT NULL)
    WHERE
        hub_id = OLD.hub_id
    ;

END;

