CREATE TABLE issues (
    id integer PRIMARY KEY NOT NULL,
    title varchar(1024) NOT NULL DEFAULT '',
    FOREIGN KEY(id) REFERENCES topics(id) ON DELETE CASCADE
);

CREATE TRIGGER
    ad_issues_1
AFTER DELETE ON
    issues
FOR EACH ROW
BEGIN
    SELECT debug(
        OLD.id
    );

    DELETE FROM
        issue_mergers
    WHERE
        issue_id = OLD.id
    ;

    DELETE FROM
        project_issues_mergers
    WHERE
        issue_id = OLD.id
    ;

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
