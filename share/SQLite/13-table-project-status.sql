CREATE TABLE project_status (
    id integer NOT NULL PRIMARY KEY,
    project_id integer NOT NULL,
    status varchar(40) NOT NULL,
    rank integer NOT NULL,
    UNIQUE (project_id,status),
    UNIQUE (id,project_id), -- projects references this
    FOREIGN KEY (id) REFERENCES topics(id) ON DELETE CASCADE,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);

CREATE TRIGGER
    ad_project_status_1
AFTER DELETE ON
    project_status
FOR EACH ROW
BEGIN
    SELECT debug(
        OLD.id
    );

    DELETE FROM
        project_status_mergers
    WHERE
        project_status_id = OLD.id
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
