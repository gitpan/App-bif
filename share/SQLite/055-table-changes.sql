CREATE TABLE changes (
    id INT NOT NULL PRIMARY KEY,
    delta_id INTEGER NOT NULL DEFAULT (nextval('deltas')),
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
    action VARCHAR,
    lang VARCHAR(8) NOT NULL DEFAULT 'en',
    message VARCHAR NOT NULL DEFAULT '',
    FOREIGN KEY(identity_id) REFERENCES identities(id)
        ON DELETE CASCADE
        DEFERRABLE INITIALLY DEFERRED,
    FOREIGN KEY(parent_id) REFERENCES changes(id)
        ON DELETE CASCADE
);

SELECT create_sequence('changes');
SELECT create_sequence('deltas');


CREATE UNIQUE INDEX
    changes_uuid
ON
    changes(uuid)
WHERE
    uuid != ''
;


CREATE TRIGGER
    changes_ai_1
AFTER INSERT ON
    changes
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
        NEW.lang,
        NEW.action
    );

    UPDATE
        changes
    SET
        itime = strftime('%s','now')
    WHERE
        id = NEW.id
    ;

    /*
     Insert a matching row in changes_tree where both parent and child
     are set to the id of the newly inserted object. Depth is set to 0
     as both child and parent are on the same level.
     */

    INSERT INTO
        changes_tree (
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
        changes_tree (
            parent,
            child,
            depth
        )
    SELECT
        x.parent,
        NEW.id,
        x.depth + 1
    FROM
        changes_tree x
    WHERE
        x.child = NEW.parent_id
    ;

    /*
        TODO document/comment the whole change process
    */
    INSERT INTO
        changes_pending(
            change_id,
            terms
        )
    SELECT
        NEW.id,
        '---' || x'0A'
            || '- _: change' || x'0A'
            || '  author: ' || COALESCE(NEW.author,'~') || x'0A'
            || '  email: ' || COALESCE(NEW.email,'~') || x'0A'
            || '  identity_uuid: ' || COALESCE(t.uuid,'~') || x'0A'
            || '  lang: ' || NEW.lang || x'0A'
            ||
                CASE WHEN
                    NEW.message = '-'
                THEN
                    '  message: ''-'''
                WHEN
                    instr(NEW.message, x'0A')
                THEN
                    '  message: "' 
                    ||  REPLACE(
                            REPLACE(NEW.message, '\\', '\\\\'),
                            x'0A', '\n'
                        )
                    || '"' || x'0A'
                ELSE
                    '  message: ' || NEW.message || x'0A'
                END
            || '  mtime: ' || NEW.mtime || x'0A'
            || '  mtimetz: ' || NEW.mtimetz || x'0A'
            || '  parent_uuid: ' || COALESCE(parent.uuid,'~') || x'0A'
    FROM
        (SELECT 1)
    LEFT JOIN
        changes AS parent
    ON
        parent.id = NEW.parent_id
    LEFT JOIN
        topics t
    ON
        t.id = NEW.identity_id
    ;

END;


CREATE TRIGGER
    changes_bu_1
BEFORE UPDATE OF
    uuid
ON
    changes
FOR EACH ROW WHEN
    OLD.uuid != NEW.uuid AND OLD.uuid != ''
BEGIN
    SELECT debug(
        'TRIGGER changes_bu_1',
        OLD.uuid,
        NEW.uuid,
        NEW.message
    );

    SELECT RAISE(ABORT, 'Bif::Error::UuidMismatch');
END;


CREATE TRIGGER
    changes_bu_2
BEFORE UPDATE OF
    id, parent_id, mtime, mtimetz, author, email, lang
ON
    changes
FOR EACH ROW
BEGIN
    SELECT RAISE (ABORT, 'Changes are immutable!');
END;


CREATE TRIGGER
    changes_au_1
AFTER UPDATE OF
    uuid
ON
    changes
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.id,
        NEW.uuid
    );

    UPDATE
        changes
    SET
        path =
            CASE WHEN
                NEW.parent_id IS NOT NULL
            THEN
                (SELECT
                    path
                 FROM
                    changes
                 WHERE
                    id = NEW.parent_id
                )
                || '/'
                || strftime('%Y%j%H%M%S',mtime,'unixepoch')
                || substr(NEW.uuid,1,2)
            ELSE
                strftime('%Y%j%H%M%S',mtime,'unixepoch')
                || substr(NEW.uuid,1,2)
            END
    WHERE
        id = NEW.id
    ;

END;


/*
    When an identity is created the initial row in the changes table
    doesn't have identity_id set. When it does get set then add the
    uuid for the identity to the pending terms calculation.

    TODO: determine if this is really necessary. It could be a problem
    because this element of the YAML probably won't be reproduced by a
    regular serialization of the change, if that is ever needed for
    something.

CREATE TRIGGER
    changes_au_2
AFTER UPDATE OF
    identity_id
ON
    changes
FOR EACH ROW
BEGIN

    UPDATE
        changes_pending
    SET
        terms = terms || (
            SELECT
                '- _: change' || x'0A'
                    || '  identity_uuid: ' || COALESCE(t.uuid,'') || x'0A'
            FROM
                (SELECT 1)
            LEFT JOIN
                topics t
            ON
                t.id = NEW.identity_id
        )
    WHERE
        change_id = NEW.id
    ;

END;
*/


CREATE TRIGGER
    changes_bd_1
BEFORE DELETE ON
    changes
FOR EACH ROW
BEGIN
    select debug(
        OLD.id
    );

    UPDATE
        project_related_changes
    SET
        merkled = 0
    WHERE
        change_id = OLD.id
    ;

END;
