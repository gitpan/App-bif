CREATE TABLE plans (
    id INTEGER NOT NULL PRIMARY KEY,
    provider_id INTEGER NOT NULL,
    name VARCHAR NOT NULL,
    title VARCHAR NOT NULL,
    UNIQUE(provider_id,name),
    FOREIGN KEY(id) REFERENCES topics(id) ON DELETE CASCADE
    FOREIGN KEY(provider_id) REFERENCES providers(id) ON DELETE CASCADE
);

CREATE TRIGGER
    plans_ad_1
AFTER DELETE ON
    plans
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
        do result in the remove of rows from [project_]issues_tomerge,
        the deletion of rows from issue_deltas just inserts more rows.

    DELETE FROM
        plans_tomerge
    WHERE
        project_id = OLD.id
    ;
    */

END;
