CREATE TABLE project_status_updates (
    update_id integer NOT NULL,
    update_order integer NOT NULL DEFAULT (nextval('update_order')),
    project_status_id integer NOT NULL,
    new integer,
    status varchar,
    rank integer,
    UNIQUE(update_id,project_status_id), -- one change per update
    FOREIGN KEY(update_id) REFERENCES updates(id) ON DELETE CASCADE
    FOREIGN KEY(project_status_id) REFERENCES project_status(id)
        ON DELETE CASCADE
);

CREATE TRIGGER
    ai_project_status_updates_1
AFTER INSERT ON
    project_status_updates
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.update_id,
        NEW.project_status_id,
        NEW.status,
        NEW.rank
    );

    UPDATE
        updates_pending
    SET
        terms = terms || (
            SELECT
                'project_status_update:' || x'0A'
                || 'project_status_uuid:' || COALESCE(topics.uuid, '') || x'0A'
                || 'status:' || COALESCE(NEW.status, '') || x'0A'
                || 'rank:' || COALESCE(NEW.rank, '') || x'0A'
            FROM
                topics
            WHERE
                topics.id = NEW.project_status_id
        )
    WHERE
        update_id = NEW.update_id
    ;

    INSERT OR IGNORE INTO
        project_status_mergers(project_status_id)
    VALUES
        (NEW.project_status_id)
    ;

    INSERT INTO
        project_related_updates(
            update_id,
            project_id
        )
    SELECT
        NEW.update_id,
        project_id
    FROM
        project_status
    WHERE
        id = NEW.project_status_id
    ;

    UPDATE
        project_status_mergers
    SET
        status = status + (NEW.status IS NOT NULL),
        rank   = rank + (NEW.rank IS NOT NULL)
    WHERE
        project_status_id = NEW.project_status_id
    ;

END;


CREATE TRIGGER
    ad_project_status_updates_1
AFTER DELETE ON
    project_status_updates
FOR EACH ROW
BEGIN

    SELECT debug(
        OLD.update_id,
        OLD.project_status_id,
        OLD.status,
        OLD.rank
    );

    INSERT OR IGNORE INTO
        project_status_mergers(project_status_id)
    VALUES
        (OLD.project_status_id)
    ;

    UPDATE
        project_status_mergers
    SET
        status = status + (OLD.status IS NOT NULL),
        rank   = rank + (OLD.rank IS NOT NULL)
    WHERE
        project_status_id = OLD.project_status_id
    ;

END;

/*
CREATE TRIGGER
    ai_project_status_updates_1
AFTER INSERT ON
    project_status_updates
FOR EACH ROW WHEN
    NEW.status IS NOT NULL
BEGIN

    SELECT debug(
        NEW.update_id,
        NEW.project_status_id,
        NEW.status,
        NEW.status,
        NEW.rank,
        NEW.def
    );

    UPDATE
        project_status
    SET
        status = (
            SELECT
                project_status_updates.status
            FROM
                (SELECT
                    updates.id,
                    MAX(updates.mtime)
                FROM
                    project_status_updates psu
                INNER JOIN
                    updates
                ON
                    updates.id = psu.update_id
                WHERE
                    psu.project_status_id
                        = NEW.project_status_id AND
                    psu.status IS NOT NULL
                ) AS latest
            INNER JOIN
                project_status_updates
            ON
                project_status_updates.update_id = latest.id
        )
    WHERE
        id = NEW.project_status_id
    ;

END;

CREATE TABLE updates_1 (
    id integer NOT NULL PRIMARY KEY,
    uuid char(40) NOT NULL UNIQUE,
    topic_id integer NOT NULL,
    parent_id integer,
    itime integer,
    mtime integer NOT NULL
        DEFAULT (strftime('%s','now')),
    mtimetz integer NOT NULL
        DEFAULT (strftime('%s','now','localtime') - strftime('%s','now')),
    path varchar,
    author varchar(255) NOT NULL,
    email varchar(255) NOT NULL,
    push_to varchar,
    lang varchar(8) NOT NULL DEFAULT 'en',
    title varchar(1024),
    message text,
    prefix varchar COLLATE NOCASE,
    FOREIGN KEY(topic_id) REFERENCES topics(id)
        ON DELETE CASCADE
        DEFERRABLE INITIALLY DEFERRED,
    FOREIGN KEY(parent_id) REFERENCES updates(id)
        ON DELETE CASCADE
);

INSERT INTO
    sqlite_sequence(name,seq)
VALUES(
    'updates',
    0
);

CREATE INDEX
    updates_prefix
ON
    updates(prefix)
;

CREATE INDEX
    updates_parent_id
ON
    updates(topic_id,parent_id)
;

CREATE TRIGGER
    ai_updates_1
AFTER INSERT ON
    updates
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.topic_id,
        NEW.update_id,
        NEW.mtime,
        NEW.mtimetz,
        NEW.title
    );

    UPDATE
        updates
    SET
        itime = strftime('%s','now')
    WHERE
        id = NEW.update_id
    ;
    
    UPDATE topics
    SET
        mtime = (
            SELECT
                MAX(mtime)
            FROM
                updates
            WHERE
                topic_id = NEW.topic_id
        ),
        mtimetz = (
            SELECT
                mtimetz
            FROM
                updates
            WHERE
                topic_id = NEW.topic_id
            ORDER BY
                mtime DESC,
                uuid DESC
            LIMIT 1
        )
    WHERE
        id = NEW.topic_id
    ;

    UPDATE topics
    SET
        title = (
            SELECT
                title
            FROM
                updates
            WHERE
                topic_id = NEW.topic_id AND title IS NOT NULL
            ORDER BY
                mtime DESC,
                uuid DESC
            LIMIT 1
        )
    WHERE
        NEW.title IS NOT NULL AND id = NEW.topic_id
    ;


END;

CREATE TRIGGER
    ad_updates_1
AFTER DELETE ON
    updates
FOR EACH ROW
BEGIN

    SELECT debug(
        OLD.topic_id
    );

    UPDATE topics
    SET
        mtime = (
            SELECT
                MAX(mtime)
            FROM
                updates
            WHERE
                topic_id = OLD.topic_id
        ),
        mtimetz = (
            SELECT
                mtimetz
            FROM
                updates
            WHERE
                topic_id = OLD.topic_id
            ORDER BY
                mtime DESC,
                uuid DESC
            LIMIT 1
        )
    WHERE
        id = OLD.topic_id
    ;

    UPDATE topics
    SET
        title = (
            SELECT
                title
            FROM
                updates
            WHERE
                topic_id = OLD.topic_id AND title IS NOT NULL
            ORDER BY
                mtime DESC,
                uuid DESC
            LIMIT 1
        )
    WHERE
        OLD.title IS NOT NULL AND id = OLD.topic_id
    ;

END;
*/

