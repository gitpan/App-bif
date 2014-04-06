CREATE TABLE project_status (
    id INTEGER NOT NULL PRIMARY KEY,
    project_id INTEGER NOT NULL,
    status VARCHAR(40) NOT NULL,
    rank INTEGER NOT NULL,
    UNIQUE (project_id,status),
    UNIQUE (id,project_id), -- projects references this
    FOREIGN KEY (id) REFERENCES topics(id) ON DELETE CASCADE,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);

CREATE TRIGGER
    bi_project_status_1
BEFORE INSERT ON
    project_status
FOR EACH ROW
BEGIN
    SELECT debug(
        'TRIGGER bi_project_status_1',
        NEW.id,
        NEW.project_id,
        NEW.status,
        NEW.rank
    );
END;

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
        project_status_tomerge
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
