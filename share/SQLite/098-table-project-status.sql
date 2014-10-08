CREATE TABLE project_status (
    id INT NOT NULL PRIMARY KEY,
    project_id INTEGER NOT NULL,
    status VARCHAR(40) NOT NULL,
    rank INTEGER NOT NULL,
    UNIQUE (project_id,status),
    UNIQUE (id,project_id), -- projects references this
    FOREIGN KEY (id) REFERENCES topics(id) ON DELETE CASCADE,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);

CREATE TRIGGER
    project_status_ad_1
AFTER DELETE ON
    project_status
FOR EACH ROW
BEGIN
    SELECT debug(
        OLD.id,
        OLD.status
    );

    /*
        The following is necessary, because although FK relationships
        do result in the remove of rows from project_status_tomerge, the
        deletion of rows from project_status_deltas just inserts more
        rows.
    */

    DELETE FROM
        project_status_tomerge
    WHERE
        project_status_id = OLD.id
    ;

END;

