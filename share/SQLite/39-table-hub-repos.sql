CREATE TABLE hub_repos (
    id INTEGER NOT NULL PRIMARY KEY,
    hub_id INTEGER NOT NULL,
    location VARCHAR NOT NULL UNIQUE,
    UNIQUE(hub_id,id),
    FOREIGN KEY(hub_id) REFERENCES hubs(id) ON DELETE CASCADE
);

CREATE TRIGGER
    hub_repos_ad_1
AFTER DELETE ON
    hub_repos
FOR EACH ROW
BEGIN
    SELECT debug(
        OLD.id,
        OLD.hub_id,
        OLD.location
    );

    DELETE FROM
        topics
    WHERE
        id = OLD.id
    ;

    /*
        The following is necessary, because although FK relationships
        do result in the remove of rows from hub_repos_tomerge, the
        deletion of rows from hub_repo_deltas just inserts more rows.
    */

    DELETE FROM
        hub_repos_tomerge
    WHERE
        hub_repo_id = OLD.id
    ;

END;
