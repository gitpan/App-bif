CREATE TABLE hub_related_projects(
    hub_id INTEGER NOT NULL,
    project_id INTEGER NOT NULL,
    update_id INTEGER NOT NULL,
    hash VARCHAR(8) NOT NULL DEFAULT '',
    UNIQUE(hub_id,project_id),
    FOREIGN KEY(hub_id) REFERENCES hubs(id) ON DELETE CASCADE,
    FOREIGN KEY(project_id) REFERENCES projects(id) ON DELETE CASCADE,
    FOREIGN KEY(update_id) REFERENCES updates(id) ON DELETE CASCADE
);
