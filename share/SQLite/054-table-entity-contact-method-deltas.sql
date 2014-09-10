CREATE TABLE entity_contact_method_deltas (
    id INTEGER NOT NULL PRIMARY KEY DEFAULT (nextval('update_order')),
    update_id INTEGER NOT NULL,
    entity_contact_method_id INTEGER NOT NULL,
    new INTEGER,
    method VARCHAR,
    mvalue VARCHAR,
    UNIQUE(update_id,entity_contact_method_id), -- one change per update
    FOREIGN KEY(update_id) REFERENCES updates(id) ON DELETE CASCADE
    FOREIGN KEY(entity_contact_method_id) REFERENCES entity_contact_methods(id)
        ON DELETE CASCADE
) WITHOUT ROWID;

CREATE TRIGGER
    entity_contact_method_deltas_ai_1
AFTER INSERT ON
    entity_contact_method_deltas
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.id,
        NEW.update_id,
        NEW.entity_contact_method_id,
        NEW.method,
        NEW.mvalue
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
                    '  - entity_contact_method:' || x'0A'
                ELSE
                    '  - entity_contact_method_delta:' || x'0A'
                    || '      entity_contact_method_uuid: '
                    || topics.uuid || x'0A'
                END
                || '      method: ' || COALESCE(NEW.method, '~') || x'0A'
                || '      mvalue: ' || COALESCE(NEW.mvalue, '~') || x'0A'
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
                topics.id = NEW.entity_contact_method_id
        )
    WHERE
        update_id = NEW.update_id
    ;

    INSERT OR IGNORE INTO
        entity_contact_methods_tomerge(entity_contact_method_id)
    VALUES
        (NEW.entity_contact_method_id)
    ;

    INSERT INTO
        entity_related_updates(
            update_id,
            entity_id
        )
    SELECT
        NEW.update_id,
        id.id
    FROM
        entity_contact_methods ecm
    INNER JOIN
        identities id
    ON
        id.id = ecm.entity_id
    WHERE
        ecm.id = NEW.entity_contact_method_id
    ;

    UPDATE
        entity_contact_methods_tomerge
    SET
        method = method + (NEW.method IS NOT NULL),
        mvalue = mvalue + (NEW.mvalue IS NOT NULL)
    WHERE
        entity_contact_method_id = NEW.entity_contact_method_id
    ;
END;


CREATE TRIGGER
    entity_contact_method_deltas_ad_1
AFTER DELETE ON
    entity_contact_method_deltas
FOR EACH ROW
BEGIN

    SELECT debug(
        OLD.update_id,
        OLD.entity_contact_method_id,
        OLD.method,
        OLD.mvalue
    );

    INSERT OR IGNORE INTO
        entity_contact_methods_tomerge(entity_contact_method_id)
    VALUES
        (OLD.entity_contact_method_id)
    ;

    UPDATE
        entity_contact_methods_tomerge
    SET
        method = method + (OLD.method IS NOT NULL),
        mvalue = mvalue + (OLD.mvalue IS NOT NULL)
    WHERE
        entity_contact_method_id = OLD.entity_contact_method_id
    ;

END;

