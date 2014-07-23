CREATE TABLE entity_deltas (
    id INTEGER NOT NULL PRIMARY KEY DEFAULT (nextval('update_order')),
    update_id INTEGER NOT NULL,
    entity_id INTEGER NOT NULL,
    contact_id INTEGER,
    default_contact_method_id INTEGER,
    name VARCHAR(128),
    new INTEGER,
    FOREIGN KEY(update_id) REFERENCES updates(id) ON DELETE CASCADE,
    FOREIGN KEY(entity_id) REFERENCES entities(id) ON DELETE CASCADE,
    FOREIGN KEY(contact_id) REFERENCES entities(id) ON DELETE CASCADE,
    FOREIGN KEY(default_contact_method_id)
        REFERENCES entity_contact_methods(id) ON DELETE CASCADE
) WITHOUT ROWID;

CREATE TRIGGER
    entity_deltas_ai_1
AFTER INSERT ON
    entity_deltas
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.update_id,
        NEW.entity_id,
        NEW.contact_id,
        NEW.default_contact_method_id,
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
                'entity_delta:' || x'0A'
                || '  entity_uuid:'
                || COALESCE(topics.uuid, '') || x'0A'
                || '  contact_uuid:'
                || COALESCE(c.uuid, '') || x'0A'
                || '  default_contact_method_uuid:'
                || COALESCE(dcm.uuid, '') || x'0A'
                || '  name:'
                || COALESCE(NEW.name, '') || x'0A'
            FROM
                topics
            LEFT JOIN
                topics c
            ON
                c.id = NEW.contact_id
            LEFT JOIN
                topics dcm
            ON
                dcm.id = NEW.default_contact_method_id
            WHERE
                topics.id = NEW.entity_id
        )
    WHERE
        update_id = NEW.update_id
    ;

    INSERT INTO
        entity_related_updates(
            update_id,
            entity_id
        )
    SELECT
        NEW.update_id,
        NEW.entity_id
    FROM
        identities id
    WHERE
        id.id = NEW.entity_id
    ;

    INSERT OR IGNORE INTO
        entities_tomerge(entity_id) VALUES (NEW.entity_id);

    UPDATE
        entities_tomerge
    SET
        contact_id = contact_id + (NEW.contact_id IS NOT NULL),
        default_contact_method_id = default_contact_method_id +
            (NEW.default_contact_method_id IS NOT NULL),
        name = name + (NEW.name IS NOT NULL)
    WHERE
        entity_id = NEW.entity_id
    ;

END;

CREATE TRIGGER
    entity_deltas_ad_1
AFTER DELETE ON
    entity_deltas
FOR EACH ROW
BEGIN

    SELECT debug(
        OLD.entity_id
    );

    INSERT OR IGNORE INTO
        entities_tomerge(entity_id) VALUES (OLD.entity_id);

    UPDATE
        entities_tomerge
    SET
        contact_id = contact_id + (OLD.contact_id IS NOT NULL),
        default_contact_method_id = default_contact_method_id +
            (OLD.default_contact_method_id IS NOT NULL),
        name = name + (OLD.name IS NOT NULL)
    WHERE
        entity_id = OLD.entity_id
    ;

END;

