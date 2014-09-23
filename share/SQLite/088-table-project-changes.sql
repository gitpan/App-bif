CREATE TABLE project_changes(
    project_id INTEGER NOT NULL,
    change_id INTEGER NOT NULL,
    UNIQUE(change_id,project_id) ON CONFLICT IGNORE
    FOREIGN KEY(change_id) REFERENCES changes(id) ON DELETE CASCADE,
    FOREIGN KEY(project_id) REFERENCES projects(id) ON DELETE CASCADE
);

CREATE INDEX
    project_changes_project_id
ON
    project_changes(project_id)
;

/*
    Project-only changes must also be recorded as hub-related changes.
*/

CREATE TRIGGER
    project_changes_ai_1
AFTER INSERT ON
    project_changes
FOR EACH ROW
BEGIN
    SELECT debug(
        NEW.project_id,
        NEW.change_id
    );


    INSERT INTO
        project_entities(
            project_id,
            entity_id
        )
    SELECT
        NEW.project_id,
        c.identity_id
    FROM
        changes c
    WHERE
        c.id = NEW.change_id
    ;


    INSERT INTO
        hub_related_changes(
            hub_id,
            change_id
        )
    SELECT
        hrp.hub_id,
        NEW.change_id
    FROM
        hub_related_projects hrp
    WHERE
        hrp.project_id = NEW.project_id
    ;
END;

-- TODO deletes?
