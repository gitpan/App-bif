CREATE TABLE hubs (
    id INT NOT NULL PRIMARY KEY,
    default_repo_id INTEGER,
    name VARCHAR(128) NOT NULL UNIQUE,
    local INTEGER UNIQUE,
    hash VARCHAR,
    num_changes INTEGER,
    FOREIGN KEY (id) REFERENCES topics(id) ON DELETE CASCADE,
    FOREIGN KEY (id,default_repo_id) REFERENCES hub_repos(hub_id,id)
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
        OLD.id,
        OLD.name
    );

    DELETE FROM
        topics
    WHERE
        id = OLD.id
    ;

    /*
        The following is necessary, because although FK relationships
        do result in the remove of rows from hubs_tomerge, the deletion
        of rows from hub_deltas just inserts more rows.
    */

    DELETE FROM
        hubs_tomerge
    WHERE
        hub_id = OLD.id
    ;

END;

