CREATE TABLE issues (
    id INTEGER PRIMARY KEY NOT NULL,
    title VARCHAR(1024) NOT NULL DEFAULT '',
    FOREIGN KEY(id) REFERENCES topics(id) ON DELETE CASCADE
);

CREATE TRIGGER
    issues_ad_1
AFTER DELETE ON
    issues
FOR EACH ROW
BEGIN
    SELECT debug(
        OLD.id,
        OLD.title
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
    */

    DELETE FROM
        issues_tomerge
    WHERE
        issue_id = OLD.id
    ;

    DELETE FROM
        project_issues_tomerge
    WHERE
        issue_id = OLD.id
    ;

END;
