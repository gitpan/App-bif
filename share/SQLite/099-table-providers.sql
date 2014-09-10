CREATE TABLE providers (
    id INTEGER NOT NULL PRIMARY KEY,
    FOREIGN KEY(id) REFERENCES entities(id) ON DELETE CASCADE
);

CREATE TRIGGER
    providers_ad_1
AFTER DELETE ON
    providers
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
        providers_tomerge
    WHERE
        project_id = OLD.id
    ;
    */

END;
