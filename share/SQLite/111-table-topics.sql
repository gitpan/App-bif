CREATE TABLE topics (
    id INT NOT NULL PRIMARY KEY,
    uuid char(40) NOT NULL UNIQUE,
    first_change_id INTEGER NOT NULL,
    last_change_id INTEGER NOT NULL,
    kind VARCHAR NOT NULL,
    ctime INTEGER NOT NULL,
    ctimetz INTEGER NOT NULL,
    ctimetzhm VARCHAR, -- NOT NULL
    mtime INTEGER NOT NULL,
    mtimetz INTEGER NOT NULL,
    mtimetzhm VARCHAR, -- NOT NULL
    lang VARCHAR(8) NOT NULL DEFAULT 'en',
    hash VARCHAR,
    delta_id INTEGER NOT NULL DEFAULT (nextval('deltas')),
    num_changes INTEGER,
    FOREIGN KEY(first_change_id) REFERENCES changes(id) ON DELETE CASCADE,
    FOREIGN KEY(last_change_id) REFERENCES changes(id) ON DELETE NO ACTION
);

SELECT create_sequence('topics');

CREATE TRIGGER
    topics_ai_1
AFTER INSERT ON
    topics
FOR EACH ROW
BEGIN
    UPDATE
        topics
    SET
        ctimetzhm = printf(
            "%+.2d%.2d",
            CAST(NEW.ctimetz / 3600 AS INTEGER),
            (
                abs(NEW.ctimetz) -
                CAST(abs(NEW.ctimetz) / 3600 AS INTEGER) * 3600
            ) / 60
        ),
        mtimetzhm = printf(
            "%+.2d%.2d",
            CAST(NEW.mtimetz / 3600 AS INTEGER),
            (
                abs(NEW.mtimetz) -
                CAST(abs(NEW.mtimetz) / 3600 AS INTEGER) * 3600
            ) / 60
        )
    WHERE
        id = NEW.id
    ;
END;


CREATE TRIGGER
    topics_au_1
AFTER UPDATE OF
    mtimetz
ON
    topics
FOR EACH ROW
BEGIN
    UPDATE
        topics
    SET
        mtimetzhm = printf(
            "%+.2d%.2d",
            CAST(NEW.mtimetz / 3600 AS INTEGER),
            (
                abs(NEW.mtimetz) -
                CAST(abs(NEW.mtimetz) / 3600 AS INTEGER) * 3600
            ) / 60
        )
    WHERE
        id = NEW.id
    ;
END;


CREATE TRIGGER
    topics_bi_1
BEFORE INSERT ON topics
FOR EACH ROW
BEGIN
    SELECT debug(
        NEW.id,
        NEW.uuid,
        NEW.first_change_id,
        NEW.last_change_id,
        NEW.kind,
        NEW.delta_id
    );

END;


CREATE TRIGGER
    topics_bu_1
BEFORE UPDATE OF
    ctime,ctimetz,first_change_id,uuid
ON
    topics
FOR EACH ROW
BEGIN
    SELECT RAISE(ABORT, 'cannot modify topics.ctime*,first_change_id,uuid');
END;


CREATE TRIGGER
    topics_bd_1
BEFORE DELETE ON topics
FOR EACH ROW
BEGIN
    SELECT debug(
        OLD.id,
        OLD.first_change_id,
        OLD.kind
    );

    DELETE FROM
        changes
    WHERE
        id = OLD.first_change_id
    ;

END;
