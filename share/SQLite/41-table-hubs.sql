CREATE TABLE hubs (
    id INTEGER NOT NULL PRIMARY KEY,
    default_repo_id INTEGER NOT NULL DEFAULT -1,
    name VARCHAR(128) NOT NULL UNIQUE,
    local INTEGER UNIQUE,
    hash VARCHAR,
    num_updates INTEGER,
    FOREIGN KEY (id) REFERENCES topics(id) ON DELETE CASCADE,
    FOREIGN KEY (id,default_repo_id)
        REFERENCES hub_repos(hub_id,id)
        DEFERRABLE INITIALLY DEFERRED,
    CONSTRAINT local_constraint CHECK (
        local = 1 OR local IS NULL
    )
);

CREATE TRIGGER
    hubs_ad_1
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
