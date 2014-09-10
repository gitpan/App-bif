CREATE TABLE topics (
    id INTEGER NOT NULL PRIMARY KEY,
    uuid char(40) NOT NULL UNIQUE,
    first_update_id INTEGER NOT NULL,
    kind VARCHAR NOT NULL,
    ctime INTEGER NOT NULL,
    ctimetz INTEGER NOT NULL,
    mtime INTEGER NOT NULL,
    mtimetz INTEGER NOT NULL,
    lang VARCHAR(8) NOT NULL DEFAULT 'en',
    hash VARCHAR,
    update_order INTEGER NOT NULL DEFAULT (nextval('update_order')),
    num_updates INTEGER,
    FOREIGN KEY(first_update_id) REFERENCES updates(id) ON DELETE CASCADE
);

SELECT create_sequence('topics');

CREATE TRIGGER
    topics_bi_1
BEFORE INSERT ON topics
FOR EACH ROW
BEGIN
    SELECT debug(
        NEW.id,
        NEW.uuid,
        NEW.first_update_id,
        NEW.kind,
        NEW.update_order
    );

END;


CREATE TRIGGER
    topics_bu_1
BEFORE UPDATE OF
    ctime,ctimetz,first_update_id,uuid
ON
    topics
FOR EACH ROW
BEGIN
    SELECT RAISE(ABORT, 'cannot modify topics.ctime*,first_update_id,uuid');
END;


CREATE TRIGGER
    topics_bd_1
BEFORE DELETE ON topics
FOR EACH ROW
BEGIN
    SELECT debug(
        OLD.id,
        OLD.first_update_id,
        OLD.kind
    );

    DELETE FROM
        updates
    WHERE
        id = OLD.first_update_id
    ;

END;
