CREATE TABLE hub_location_updates (
    id INTEGER NOT NULL PRIMARY KEY DEFAULT (nextval('update_order')),
    update_id INTEGER NOT NULL,
    hub_location_id INTEGER NOT NULL,
    new INTEGER,
    location VARCHAR,
    UNIQUE(update_id,hub_location_id), -- one change per update
    FOREIGN KEY(update_id) REFERENCES updates(id) ON DELETE CASCADE
    FOREIGN KEY(hub_location_id) REFERENCES hub_locations(id)
        ON DELETE CASCADE
) WITHOUT ROWID;

CREATE TRIGGER
    ai_hub_location_updates_1
AFTER INSERT ON
    hub_location_updates
FOR EACH ROW
BEGIN

    SELECT debug(
        'TRIGGER ai_hub_location_updates_1',
        NEW.id,
        NEW.update_id,
        NEW.hub_location_id,
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
                'hub_location_update:' || x'0A'
                || '  hub_location_uuid:' || COALESCE(topics.uuid, '') || x'0A'
                || '  location:' || COALESCE(NEW.location, '') || x'0A'
            FROM
                topics
            WHERE
                topics.id = NEW.hub_location_id
        )
    WHERE
        update_id = NEW.update_id
    ;

    INSERT OR IGNORE INTO
        hub_locations_tomerge(hub_location_id)
    VALUES
        (NEW.hub_location_id)
    ;

    INSERT INTO
        hub_related_updates(
            update_id,
            hub_id
        )
    SELECT
        NEW.update_id,
        hl.hub_id
    FROM
        hub_locations hl
    WHERE
        id = NEW.hub_location_id
    ;

    UPDATE
        hub_locations_tomerge
    SET
        location = location + (NEW.location IS NOT NULL)
    WHERE
        hub_location_id = NEW.hub_location_id
    ;
END;


CREATE TRIGGER
    ad_hub_location_updates_1
AFTER DELETE ON
    hub_location_updates
FOR EACH ROW
BEGIN

    SELECT debug(
        'TRIGGER ad_hub_location_updates_1',
        OLD.update_id,
        OLD.hub_location_id,
        OLD.location
    );

    INSERT OR IGNORE INTO
        hub_locations_tomerge(hub_location_id)
    VALUES
        (OLD.hub_location_id)
    ;

    UPDATE
        hub_locations_tomerge
    SET
        location = location + (OLD.location IS NOT NULL)
    WHERE
        hub_location_id = OLD.hub_location_id
    ;

END;
