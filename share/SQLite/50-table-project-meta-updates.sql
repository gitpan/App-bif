CREATE TABLE project_meta_updates(
    project_id INTEGER NOT NULL,
    update_id INTEGER NOT NULL,
    UNIQUE(update_id,project_id) ON CONFLICT IGNORE
    FOREIGN KEY(update_id) REFERENCES updates(id) ON DELETE CASCADE,
    FOREIGN KEY(project_id) REFERENCES projects(id) ON DELETE CASCADE
);

CREATE INDEX
    project_meta_updates_project_id
ON
    project_meta_updates(project_id)
;

/*
    Project-only updates must also be recorded as hub-related updates.
*/

CREATE TRIGGER
    ai_project_meta_updates
AFTER INSERT ON
    project_meta_updates
FOR EACH ROW
BEGIN
    SELECT debug(
        NEW.project_id,
        NEW.update_id
    );


    INSERT INTO
        hub_related_updates(
            hub_id,
            update_id
        )
    SELECT
        hrp.hub_id,
        NEW.update_id
    FROM
        hub_related_projects hrp
    WHERE
        hrp.project_id = NEW.project_id
    ;
END;
