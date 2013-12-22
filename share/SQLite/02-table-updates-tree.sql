CREATE TABLE updates_tree (
    treeid INTEGER PRIMARY KEY,
    parent integer NOT NULL,
    child  integer NOT NULL,
    depth  INTEGER NOT NULL,
    UNIQUE (parent, child)
    FOREIGN KEY(parent) REFERENCES updates(id) ON DELETE CASCADE,
    FOREIGN KEY(child) REFERENCES updates(id) ON DELETE CASCADE
);
