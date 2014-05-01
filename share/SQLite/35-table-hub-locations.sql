CREATE TABLE hub_locations (
    id INTEGER NOT NULL PRIMARY KEY,
    hub_id INTEGER NOT NULL,
    location VARCHAR NOT NULL UNIQUE,
    UNIQUE(hub_id,id),
    FOREIGN KEY(hub_id) REFERENCES hubs(id) ON DELETE CASCADE
);
