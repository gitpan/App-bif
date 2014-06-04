CREATE TABLE hub_deltas (
    id INTEGER NOT NULL PRIMARY KEY DEFAULT (nextval('update_order')),
    update_id INTEGER NOT NULL,
    hub_id INTEGER NOT NULL,
    name VARCHAR(128),
    default_location_id INTEGER,
    project_id INTEGER,
    related_update_uuid VARCHAR,
    new INTEGER,
    FOREIGN KEY(update_id) REFERENCES updates(id) ON DELETE CASCADE,
    FOREIGN KEY(hub_id) REFERENCES hubs(id) ON DELETE CASCADE,
    FOREIGN KEY(default_location_id) REFERENCES hub_repos(id)
        ON DELETE CASCADE,
    FOREIGN KEY(project_id) REFERENCES projects(id) ON DELETE CASCADE
) WITHOUT ROWID;

CREATE TRIGGER
    hub_deltas_ai_1
AFTER INSERT ON
    hub_deltas
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.update_id,
        NEW.hub_id,
        NEW.name,
        NEW.default_location_id,
        NEW.project_id,
        NEW.related_update_uuid
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
                'hub_delta:' || x'0A'
                || '  hub_uuid:'
                || COALESCE(topics.uuid, '') || x'0A'
                || '  name:'
                || COALESCE(NEW.name, '') || x'0A'
                || '  default_location_uuid:'
                || COALESCE(location.uuid, '') || x'0A'
                || '  project_uuid:'
                || COALESCE(p.uuid, '') || x'0A'
                || '  related_update_uuid:'
                || COALESCE(NEW.related_update_uuid, '') || x'0A'
            FROM
                topics
            LEFT JOIN
                topics AS location
            ON
                location.id = NEW.default_location_id
            LEFT JOIN
                topics p
            ON
                p.id = NEW.project_id
            WHERE
                topics.id = NEW.hub_id
        )
    WHERE
        update_id = NEW.update_id
    ;

    INSERT INTO
        hub_related_updates(
            update_id,
            hub_id
        )
    VALUES (
        NEW.update_id,
        NEW.hub_id
    );

    INSERT INTO
        hub_related_projects(
            hub_id,
            project_id,
            update_id
        )
    SELECT
        NEW.hub_id,
        NEW.project_id,
        NEW.update_id
    WHERE
        NEW.project_id IS NOT NULL
    ;

    INSERT OR IGNORE INTO
        hub_tomerge(hub_id) VALUES (NEW.hub_id);

    UPDATE
        hub_tomerge
    SET
        name = name + (NEW.name IS NOT NULL),
        default_location_id = default_location_id +
        (NEW.default_location_id IS NOT NULL)
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
        OLD.hub_id,
        OLD.default_location_id
    );

    INSERT OR IGNORE INTO
        hub_tomerge(hub_id) VALUES (OLD.hub_id);

    UPDATE
        hub_tomerge
    SET
        name = name + (OLD.name IS NOT NULL),
        default_location_id = default_location_id +
        (OLD.default_location_id IS NOT NULL)
    WHERE
        hub_id = OLD.hub_id
    ;

END;

