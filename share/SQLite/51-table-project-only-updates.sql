CREATE TABLE project_only_updates(
    project_id INTEGER NOT NULL,
    update_id INTEGER NOT NULL,
    UNIQUE(update_id,project_id) ON CONFLICT IGNORE
    FOREIGN KEY(update_id) REFERENCES updates(id) ON DELETE CASCADE,
    FOREIGN KEY(project_id) REFERENCES projects(id) ON DELETE CASCADE
);

CREATE INDEX
    project_only_updates_project_id
ON
    project_only_updates(project_id)
;

/*
    Project-only updates must also be recorded as hub-related updates.
*/

CREATE TRIGGER
    project_only_updates_ai_1
AFTER INSERT ON
    project_only_updates
FOR EACH ROW
BEGIN
    SELECT debug(
        NEW.project_id,
        NEW.update_id
    );


    INSERT INTO
        project_entities(
            project_id,
            entity_id
        )
    SELECT
        NEW.project_id,
        u.identity_id
    FROM
        updates u
    WHERE
        u.id = NEW.update_id
    ;


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

-- TODO deletes?
