CREATE TABLE entity_related_updates(
    entity_id INTEGER NOT NULL,
    update_id INTEGER NOT NULL,
    merkled INTEGER NOT NULL DEFAULT 0,
    UNIQUE(entity_id,update_id) ON CONFLICT IGNORE,
    CHECK (merkled = 0 OR merkled = 1),
    FOREIGN KEY(entity_id) REFERENCES entities(id) ON DELETE CASCADE,
    FOREIGN KEY(update_id) REFERENCES updates(id) ON DELETE CASCADE
);

/*
    Only need to do this for update_id as the UNIQUE condition above
    should work as a covering index for "WHERE entity_id =" expressions.
*/
CREATE INDEX
    entity_related_updates_update_id
ON
    entity_related_updates(update_id)
;

CREATE TRIGGER
    entity_related_updates_ai_1
AFTER INSERT ON
    entity_related_updates
FOR EACH ROW
BEGIN
    SELECT debug(
        NEW.entity_id,
        NEW.update_id
    );

    INSERT INTO
        hub_related_updates(
            hub_id,
            update_id
        )
    SELECT
        he.hub_id,
        NEW.update_id
    FROM
        hub_entities he
    WHERE
        he.entity_id = NEW.entity_id
    ;

END;

