CREATE TABLE repo_locations (
    id INTEGER NOT NULL PRIMARY KEY,
    repo_id INTEGER NOT NULL,
    location VARCHAR NOT NULL UNIQUE,
    UNIQUE(repo_id,id),
    FOREIGN KEY(repo_id) REFERENCES repos(id) ON DELETE CASCADE
);
