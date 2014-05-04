CREATE TABLE project_related_projects(
    project_id INTEGER NOT NULL,
    related_id INTEGER NOT NULL,
    UNIQUE(project_id,related_id) ON CONFLICT IGNORE,
    FOREIGN KEY(project_id) REFERENCES projects(id) ON DELETE CASCADE,
    FOREIGN KEY(related_id) REFERENCES projects(id) ON DELETE CASCADE
);
