CREATE TABLE topics (
    id integer NOT NULL PRIMARY KEY,
    uuid char(40) NOT NULL UNIQUE DEFAULT '',
    first_update_id INTEGER NOT NULL,
    kind varchar NOT NULL,
    ctime integer NOT NULL,
    ctimetz integer NOT NULL,
    mtime integer NOT NULL,
    mtimetz integer NOT NULL,
    lang varchar(8) NOT NULL DEFAULT 'en',
    hash varchar,
    num_updates integer,
    FOREIGN KEY(first_update_id) REFERENCES updates(id) ON DELETE CASCADE
);

SELECT create_sequence('topics');

CREATE TRIGGER
    bi_topics_1
BEFORE INSERT ON topics
FOR EACH ROW
BEGIN
    SELECT debug(
        'TRIGGER bi_topics_1',
        NEW.id,
        NEW.uuid,
        NEW.first_update_id,
        NEW.kind
    );

END;

CREATE TRIGGER
    bu_topics
BEFORE UPDATE OF
    ctime,ctimetz,first_update_id
ON
    topics
FOR EACH ROW
BEGIN
    SELECT RAISE(ABORT, 'cannot modify topics.ctime*,first_update_id');
END;

CREATE TRIGGER
    bd_topics_1
BEFORE DELETE ON topics
FOR EACH ROW
BEGIN
    SELECT debug(
        'TRIGGER bd_topics_1',
        OLD.id,
        OLD.first_update_id,
        OLD.kind
    );

END;
