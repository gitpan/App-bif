CREATE TABLE entity_contact_methods (
    id INTEGER NOT NULL PRIMARY KEY,
    entity_id INTEGER NOT NULL,
    method VARCHAR NOT NULL,
    mvalue VARCHAR NOT NULL,
    UNIQUE(entity_id,id), -- used by entities FK
    UNIQUE(entity_id,method,mvalue),
    FOREIGN KEY(entity_id) REFERENCES entities(id) ON DELETE CASCADE
);

CREATE TRIGGER
    entity_contact_methods_ad_1
AFTER DELETE ON
    entity_contact_methods
FOR EACH ROW
BEGIN
    SELECT debug(
        OLD.id,
        OLD.entity_id,
        OLD.method
    );

    DELETE FROM
        topics
    WHERE
        id = OLD.id
    ;

    /*
        The following is necessary, because although FK relationships
        do result in the remove of rows from
        entity_contact_methods_tomerge, the deletion of rows from
        entity_contact_method_deltas just inserts more rows.
    */

    DELETE FROM
        entity_contact_methods_tomerge
    WHERE
        entity_contact_method_id = OLD.id
    ;

END;
