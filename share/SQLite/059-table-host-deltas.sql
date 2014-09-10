CREATE TABLE host_deltas (
    id INTEGER NOT NULL PRIMARY KEY DEFAULT (nextval('update_order')),
    update_id INTEGER NOT NULL,
    host_id INTEGER NOT NULL,
    name VARCHAR,
    new INTEGER,
    FOREIGN KEY(update_id) REFERENCES updates(id) ON DELETE CASCADE,
    FOREIGN KEY(host_id) REFERENCES hosts(id) ON DELETE CASCADE
) WITHOUT ROWID;

CREATE TRIGGER
    host_deltas_ai_1
AFTER INSERT ON
    host_deltas
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.update_id,
        NEW.host_id,
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
                    '  - host:' || x'0A'
                ELSE
                    '  - host_delta:' || x'0A'
                    || '      host_uuid: ' || topics.uuid || x'0A'
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
                topics.id = NEW.host_id
        )
    WHERE
        update_id = NEW.update_id
    ;

/*
    INSERT INTO
        entity_related_updates(
            entity_id,
            update_id
        )
    VALUES (
        NEW.host_id,
        NEW.update_id
    );
*/

END;
