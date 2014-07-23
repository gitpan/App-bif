CREATE TABLE identity_deltas (
    id INTEGER NOT NULL PRIMARY KEY DEFAULT (nextval('update_order')),
    update_id INTEGER NOT NULL,
    identity_id INTEGER NOT NULL,
    new INTEGER,
    FOREIGN KEY(update_id) REFERENCES updates(id) ON DELETE CASCADE,
    FOREIGN KEY(identity_id) REFERENCES identities(id) ON DELETE CASCADE
) WITHOUT ROWID;

CREATE TRIGGER
    identity_deltas_ai_1
AFTER INSERT ON
    identity_deltas
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.update_id,
        NEW.identity_id
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
                'identity_delta:' || x'0A'
                || '  identity_uuid:'
                || COALESCE(topics.uuid, '') || x'0A'
            FROM
                topics
            WHERE
                topics.id = NEW.identity_id
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
        NEW.identity_id,
        NEW.update_id
    );

END;
