CREATE TABLE hub_entities(
    hub_id INTEGER NOT NULL,
    entity_id INTEGER NOT NULL,
    hash VARCHAR(8) NOT NULL DEFAULT '',
    UNIQUE(hub_id,entity_id) ON CONFLICT IGNORE,
    FOREIGN KEY(hub_id) REFERENCES hubs(id) ON DELETE CASCADE,
    FOREIGN KEY(entity_id) REFERENCES entities(id) ON DELETE CASCADE
);

CREATE TRIGGER
    hub_entities_ai_1
AFTER INSERT ON
    hub_entities
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.hub_id,
        NEW.entity_id,
        NEW.hash
    );

    INSERT INTO
        hub_related_changes(
            hub_id,
            change_id
        )
    SELECT
        NEW.hub_id,
        eru.change_id
    FROM
        entity_related_changes eru
    WHERE
        eru.entity_id = NEW.entity_id
    ;

END;

CREATE TRIGGER
    hub_entities_ad_1
AFTER DELETE ON
    hub_entities
FOR EACH ROW
BEGIN
    SELECT debug(
        OLD.hub_id,
        OLD.entity_id,
        OLD.hash
    );

    DELETE FROM
        hub_related_changes
    WHERE
        hub_id = OLD.hub_ID AND
        change_id IN (
            SELECT
                eru.change_id
            FROM
                entity_related_changes eru
            WHERE
                eru.entity_id = OLD.entity_id
        )
    ;
END;
