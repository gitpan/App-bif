CREATE TABLE entities (
    id INT NOT NULL PRIMARY KEY,
    contact_id INTEGER NOT NULL DEFAULT -1,
    default_contact_method_id INTEGER NOT NULL DEFAULT -1,
    name VARCHAR(128) NOT NULL,
    local INTEGER DEFAULT 0,
    hash VARCHAR,
    num_changes INTEGER,
    FOREIGN KEY (id) REFERENCES topics(id) ON DELETE CASCADE,
    FOREIGN KEY (contact_id)
        REFERENCES entities(id) ON DELETE CASCADE
        DEFERRABLE INITIALLY DEFERRED,
    FOREIGN KEY (contact_id,default_contact_method_id)
        REFERENCES entity_contact_methods(entity_id,id)
        DEFERRABLE INITIALLY DEFERRED,
    CONSTRAINT local_constraint CHECK (
        local = 1 OR local = 0
    )
);

CREATE TRIGGER
    entities_ad_1
AFTER DELETE ON
    entities
FOR EACH ROW
BEGIN
    SELECT debug(
        OLD.id
    );

    DELETE FROM
        topics
    WHERE
        id = OLD.id
    ;

    /*
        The following is necessary, because although FK relationships
        do result in the remove of rows from entities_tomerge, the
        deletion of rows from entity_deltas just inserts more rows.
    */
    DELETE FROM
        entities_tomerge
    WHERE
        entity_id = OLD.id
    ;

END;
