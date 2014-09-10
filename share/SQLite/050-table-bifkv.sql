CREATE TABLE bifkv (
    key VARCHAR NOT NULL PRIMARY KEY,
    identity_id INTEGER,
    update_id INTEGER,
    UNIQUE(key,update_id),
    UNIQUE(key,identity_id),
    FOREIGN KEY(identity_id) REFERENCES identities(id) ON DELETE CASCADE,
    FOREIGN KEY(update_id) REFERENCES updates(id) ON DELETE CASCADE
);
