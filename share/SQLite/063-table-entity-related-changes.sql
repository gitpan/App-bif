CREATE TABLE entity_related_changes(
    entity_id INTEGER NOT NULL,
    change_id INTEGER NOT NULL,
    merkled INTEGER NOT NULL DEFAULT 0,
    UNIQUE(entity_id,change_id) ON CONFLICT IGNORE,
    CHECK (merkled = 0 OR merkled = 1),
    FOREIGN KEY(entity_id) REFERENCES entities(id) ON DELETE CASCADE,
    FOREIGN KEY(change_id) REFERENCES changes(id) ON DELETE CASCADE
);

/*
    Only need to do this for change_id as the UNIQUE condition above
    should work as a covering index for "WHERE entity_id =" expressions.
*/
CREATE INDEX
    entity_related_changes_change_id
ON
    entity_related_changes(change_id)
;

CREATE TRIGGER
    entity_related_changes_ai_1
AFTER INSERT ON
    entity_related_changes
FOR EACH ROW
BEGIN
    SELECT debug(
        NEW.entity_id,
        NEW.change_id
    );

    INSERT INTO
        hub_related_changes(
            hub_id,
            change_id
        )
    SELECT
        he.hub_id,
        NEW.change_id
    FROM
        hub_entities he
    WHERE
        he.entity_id = NEW.entity_id
    ;

END;

