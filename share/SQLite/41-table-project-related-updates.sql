CREATE TABLE project_related_updates(
    update_id INTEGER NOT NULL,
    project_id INTEGER NOT NULL,
    project_only INTEGER,
    UNIQUE(update_id,project_id) ON CONFLICT IGNORE
    FOREIGN KEY(update_id) REFERENCES updates(id) ON DELETE CASCADE,
    FOREIGN KEY(project_id) REFERENCES projects(id) ON DELETE CASCADE
);

CREATE INDEX
    project_related_updates_project_id
ON
    project_related_updates(project_id)
;
