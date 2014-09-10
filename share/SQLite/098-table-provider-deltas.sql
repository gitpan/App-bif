CREATE TABLE provider_deltas (
    id INTEGER NOT NULL PRIMARY KEY DEFAULT (nextval('update_order')),
    update_id INTEGER NOT NULL,
    provider_id INTEGER NOT NULL,
    name VARCHAR,
    new INTEGER,
    FOREIGN KEY(update_id) REFERENCES updates(id) ON DELETE CASCADE,
    FOREIGN KEY(provider_id) REFERENCES providers(id) ON DELETE CASCADE
) WITHOUT ROWID;

CREATE TRIGGER
    provider_deltas_ai_1
AFTER INSERT ON
    provider_deltas
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.update_id,
        NEW.provider_id,
        NEW.name
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
                    '  - provider:' || x'0A'
                ELSE
                    '  - provider_delta:' || x'0A'
                    || '      provider_uuid: ' || topics.uuid || x'0A'
                END
                || '      name: ' || COALESCE(NEW.name,'~') || x'0A'
                || CASE WHEN
                    NEW.new
                THEN
                    '      topic_uuid: ' || topics.uuid || x'0A'
                ELSE
                    ''
                END
            FROM
                topics
            WHERE
                topics.id = NEW.provider_id
        )
    WHERE
        update_id = NEW.update_id
    ;

    INSERT INTO
        entity_related_updates(
            entity_id,
            update_id
        )
    VALUES (
        NEW.provider_id,
        NEW.update_id
    );

END;
