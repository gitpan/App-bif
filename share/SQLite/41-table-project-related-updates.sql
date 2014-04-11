CREATE TABLE project_related_updates(
    update_id INTEGER NOT NULL,
    project_id INTEGER NOT NULL,
    project_only INTEGER,
    UNIQUE(update_id,project_id) ON CONFLICT IGNORE
    FOREIGN KEY(update_id) REFERENCES updates(id) ON DELETE CASCADE,
    FOREIGN KEY(project_id) REFERENCES projects(id) ON DELETE CASCADE,
    CONSTRAINT pru_project_only CHECK (
        project_only = 1 OR project_only IS NULL
    )
);

CREATE INDEX
    project_related_updates_project_id
ON
    project_related_updates(project_id)
;

/*
    If a project has been exported to a hub, then any project-only
    updates must also be recorded as repo-related updates.
*/

CREATE TRIGGER
    ai_project_related_updates
AFTER INSERT ON
    project_related_updates
FOR EACH ROW WHEN
    NEW.project_only = 1
BEGIN
    INSERT INTO
        repo_related_updates(
            repo_id,
            update_id
        )
    SELECT
        p.repo_id,
        NEW.update_id
    FROM
        projects p
    WHERE
        p.id = NEW.project_id AND
        p.repo_id IS NOT NULL
    ;
END;
