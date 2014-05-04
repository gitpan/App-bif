CREATE TABLE hub_related_projects(
    update_id INTEGER NOT NULL,
    hub_id INTEGER NOT NULL,
    project_id INTEGER NOT NULL,
    UNIQUE(hub_id,project_id),
    FOREIGN KEY(update_id) REFERENCES updates(id) ON DELETE CASCADE,
    FOREIGN KEY(hub_id) REFERENCES hubs(id) ON DELETE CASCADE,
    FOREIGN KEY(project_id) REFERENCES projects(id) ON DELETE CASCADE
);
