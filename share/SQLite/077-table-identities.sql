CREATE TABLE identities (
    id INTEGER NOT NULL PRIMARY KEY,
    shortname VARCHAR,
    hash VARCHAR,
    num_changes INTEGER,
    FOREIGN KEY (id) REFERENCES entities(id) ON DELETE CASCADE
);

CREATE TRIGGER
    identities_ad_1
AFTER DELETE ON
    identities
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
        do result in the remove of rows from identities_tomerge, the
        deletion of rows from identity_deltas just inserts more rows.
    */
    DELETE FROM
        identities_tomerge
    WHERE
        identity_id = OLD.id
    ;

END;
