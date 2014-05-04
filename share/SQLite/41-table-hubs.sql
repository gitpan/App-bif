CREATE TABLE hubs (
    id INTEGER NOT NULL PRIMARY KEY,
    default_location_id INTEGER NOT NULL DEFAULT -1,
    alias VARCHAR(40) NOT NULL UNIQUE,
    local INTEGER UNIQUE,
    hash VARCHAR,
    num_updates INTEGER,
    FOREIGN KEY (id) REFERENCES topics(id) ON DELETE CASCADE,
    FOREIGN KEY (id,default_location_id)
        REFERENCES hub_locations(hub_id,id)
        DEFERRABLE INITIALLY DEFERRED,
    CONSTRAINT local_constraint CHECK (
        local = 1 OR local IS NULL
    )
);

CREATE TRIGGER
    ad_hubs_1
AFTER DELETE ON
    hubs
FOR EACH ROW
BEGIN
    SELECT debug(
        OLD.id
    );

    -- TODO Should this be done generically in topics?
    DELETE FROM
        updates
    WHERE
        id = (
            SELECT
                first_update_id
            FROM
                topics
            WHERE
                id = OLD.id
        )
    ;

END;
