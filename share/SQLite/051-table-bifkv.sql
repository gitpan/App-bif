CREATE TABLE bifkv (
    key VARCHAR NOT NULL PRIMARY KEY,
    identity_id INTEGER,
    change_id INTEGER,
    change_id2 INTEGER,
    FOREIGN KEY(identity_id) REFERENCES identities(id) ON DELETE CASCADE,
    FOREIGN KEY(change_id) REFERENCES changes(id) ON DELETE CASCADE,
    FOREIGN KEY(change_id2) REFERENCES changes(id) ON DELETE CASCADE
);
