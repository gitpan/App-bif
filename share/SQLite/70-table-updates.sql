CREATE TABLE updates (
    id INTEGER NOT NULL PRIMARY KEY,
    uuid char(40) NOT NULL DEFAULT '',
    parent_id INTEGER,
    ucount INTEGER NOT NULL DEFAULT 1,
    itime INTEGER,
    mtime INTEGER NOT NULL
        DEFAULT (strftime('%s','now')),
    mtimetz INTEGER NOT NULL
        DEFAULT (strftime('%s','now','localtime') - strftime('%s','now')),
    path VARCHAR,
    identity_id INTEGER NOT NULL DEFAULT -1,
    author VARCHAR(255),
    email VARCHAR(255),
    lang VARCHAR(8) NOT NULL DEFAULT 'en',
    message text NOT NULL DEFAULT '',
    prefix VARCHAR COLLATE NOCASE,
    FOREIGN KEY(identity_id) REFERENCES identities(id)
        ON DELETE CASCADE
        DEFERRABLE INITIALLY DEFERRED,
    FOREIGN KEY(parent_id) REFERENCES updates(id)
        ON DELETE CASCADE
);

SELECT create_sequence('updates');
SELECT create_sequence('update_order');

CREATE INDEX updates_prefix ON updates(prefix) ;

CREATE UNIQUE INDEX
    updates_uuid
ON
    updates(uuid)
WHERE
    uuid != ''
;

CREATE TRIGGER
    updates_ai_1
AFTER INSERT ON
    updates
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.id,
        NEW.uuid,
        NEW.parent_id,
        NEW.mtime,
        NEW.mtimetz,
        NEW.author,
        NEW.email,
        NEW.lang
    );

    UPDATE
        updates
    SET
        itime = strftime('%s','now')
    WHERE
        id = NEW.id
    ;

    /*
     Insert a matching row in updates_tree where both parent and child
     are set to the id of the newly inserted object. Depth is set to 0
     as both child and parent are on the same level.
     */

    INSERT INTO
        updates_tree (
            parent,
            child,
            depth
        )
    VALUES (
        NEW.id,
        NEW.id,
        0
    );

    /*
     Copy all rows that our parent had as its parents, but we modify
     the child id in these rows to be the id of currently inserted row,
     and increase depth by one.
     */

    INSERT INTO
        updates_tree (
            parent,
            child,
            depth
        )
    SELECT
        x.parent,
        NEW.id,
        x.depth + 1
    FROM
        updates_tree x
    WHERE
        x.child = NEW.parent_id
    ;

    /*
        TODO document/comment the whole update process
    */
    INSERT INTO
        updates_pending(
            update_id,
            terms
        )
    SELECT
        NEW.id,
        'update:' || x'0A'
            || '  author:' || COALESCE(NEW.author,'') || x'0A'
            || '  email:' || COALESCE(NEW.email,'') || x'0A'
            || '  identity_uuid:' || COALESCE(t.uuid,'') || x'0A'
            || '  lang:' || NEW.lang || x'0A'
            || '  message:' || NEW.message || x'0A'
            || '  mtime:' || NEW.mtime || x'0A'
            || '  mtimetz:' || NEW.mtimetz || x'0A'
            || '  parent_uuid:' || COALESCE(parent.uuid,'') || x'0A'
    FROM
        (SELECT 1)
    LEFT JOIN
        updates AS parent
    ON
        parent.id = NEW.parent_id
    LEFT JOIN
        topics t
    ON
        t.id = NEW.identity_id
    ;

END;


CREATE TRIGGER
    updates_bu_1
BEFORE UPDATE OF
    uuid
ON
    updates
FOR EACH ROW WHEN
    OLD.uuid != NEW.uuid AND OLD.uuid != ''
BEGIN
    SELECT debug(
        'TRIGGER updates_bu_1',
        OLD.uuid,
        NEW.uuid,
        NEW.message
    );

    SELECT RAISE(ABORT, 'Bif::Error::UuidMismatch');
END;


CREATE TRIGGER
    updates_bu_2
BEFORE UPDATE OF
    id, parent_id, mtime, mtimetz, author, email, lang
ON
    updates
FOR EACH ROW
BEGIN
    SELECT RAISE (ABORT, 'Updates are immutable!');
END;


CREATE TRIGGER
    updates_au_1
AFTER UPDATE OF
    prefix
ON
    updates
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.id,
        NEW.prefix
    );

    UPDATE
        updates
    SET
        path =
            CASE WHEN
                NEW.parent_id IS NOT NULL
            THEN
                (SELECT
                    path
                 FROM
                    updates
                 WHERE
                    id = NEW.parent_id
                )
                || '/'
                || strftime('%Y%j%H%M%S',mtime,'unixepoch')
                || substr(NEW.prefix,1,2)
            ELSE
                strftime('%Y%j%H%M%S',mtime,'unixepoch')
                || substr(NEW.prefix,1,2)
            END
    WHERE
        id = NEW.id
    ;

END;

/*
    When an identity is created the initial row in the updates table
    doesn't have identity_id set. When it does get set then add the
    uuid for the identity to the pending terms calculation.
*/
CREATE TRIGGER
    updates_au_2
AFTER UPDATE OF
    identity_id
ON
    updates
FOR EACH ROW
BEGIN

    UPDATE
        updates_pending
    SET
        terms = terms || (
            SELECT
                'update:' || x'0A'
                    || '  identity_uuid:' || COALESCE(t.uuid,'') || x'0A'
            FROM
                (SELECT 1)
            LEFT JOIN
                topics t
            ON
                t.id = NEW.identity_id
        )
    WHERE
        update_id = NEW.id
    ;

END;
