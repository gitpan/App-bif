CREATE TABLE identity_self (
    id INTEGER NOT NULL PRIMARY KEY
        REFERENCES identities(id) ON DELETE CASCADE
);

CREATE TRIGGER
    identity_self_bi_1
BEFORE INSERT ON
    identity_self
FOR EACH ROW WHEN EXISTS
    ( SELECT id FROM identity_self )
BEGIN
    SELECT RAISE(ABORT, 'There can be only one self');
END;

