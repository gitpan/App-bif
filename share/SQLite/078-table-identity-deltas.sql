CREATE TABLE identity_deltas (
    id INT NOT NULL PRIMARY KEY DEFAULT (nextval('deltas')),
    change_id INTEGER NOT NULL,
    identity_id INTEGER NOT NULL,
    shortname VARCHAR,
    new INTEGER,
    FOREIGN KEY(change_id) REFERENCES changes(id) ON DELETE CASCADE,
    FOREIGN KEY(identity_id) REFERENCES identities(id) ON DELETE CASCADE
);

CREATE TRIGGER
    identity_deltas_ai_1
AFTER INSERT ON
    identity_deltas
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.change_id,
        NEW.identity_id,
        NEW.shortname
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
        id = NEW.identity_id
    ;

    UPDATE
        changes_pending
    SET
        terms = terms || (
            SELECT
                CASE WHEN
                    NEW.new
                THEN
                    '- _: identity' || x'0A'
                ELSE
                    '- _: identity_delta' || x'0A'
                    || '  identity_uuid: ' || topics.uuid || x'0A'
                END
                || '  shortname: ' || COALESCE(NEW.shortname,'~') || x'0A'
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
                topics.id = NEW.identity_id
        )
    WHERE
        change_id = NEW.change_id
    ;

    INSERT OR IGNORE INTO
        identities_tomerge(identity_id) VALUES (NEW.identity_id);

    UPDATE
        identities_tomerge
    SET
        shortname = shortname + (NEW.shortname IS NOT NULL)
    WHERE
        identity_id = NEW.identity_id
    ;

    INSERT INTO
        entity_related_changes(
            entity_id,
            change_id
        )
    VALUES (
        NEW.identity_id,
        NEW.change_id
    );

END;
