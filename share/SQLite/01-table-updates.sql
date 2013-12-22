CREATE TABLE updates (
    id integer NOT NULL PRIMARY KEY,
    uuid char(40) NOT NULL UNIQUE DEFAULT '',
    parent_id integer,
    itime integer,
    mtime integer NOT NULL
        DEFAULT (strftime('%s','now')),
    mtimetz integer NOT NULL
        DEFAULT (strftime('%s','now','localtime') - strftime('%s','now')),
    path varchar,
    author varchar(255) NOT NULL,
    email varchar(255) NOT NULL,
    lang varchar(8) NOT NULL DEFAULT 'en',
    message text NOT NULL DEFAULT '',
    prefix varchar COLLATE NOCASE,
    FOREIGN KEY(parent_id) REFERENCES updates(id)
        ON DELETE CASCADE
);

SELECT create_sequence('updates');
SELECT create_sequence('update_order');

CREATE INDEX updates_prefix ON updates(prefix) ;

CREATE TRIGGER
    ai_updates_1
AFTER INSERT ON
    updates
FOR EACH ROW
BEGIN

    SELECT debug(
        'TRIGGER ai_updates_1',
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
            || 'author:' || NEW.author || x'0A'
            || 'email:' || NEW.email || x'0A'
            || 'lang:' || NEW.lang || x'0A'
            || 'message:' || NEW.message || x'0A'
            || 'mtime:' || NEW.mtime || x'0A'
            || 'mtimetz:' || NEW.mtimetz || x'0A'
            || 'parent_uuid:' || COALESCE(parent.uuid,'') || x'0A'
    FROM
        (SELECT 1)
    LEFT JOIN
        updates AS parent
    ON
        parent.id = NEW.parent_id
    ;

END;


CREATE TRIGGER
    tree_bu_updates_1
BEFORE UPDATE OF
    id, parent_id, mtime, mtimetz, author, email, lang
ON
    updates
FOR EACH ROW
BEGIN
    SELECT RAISE (ABORT, 'Updates are immutable!');
END;


CREATE TRIGGER
    bu_updates_1
BEFORE UPDATE OF
    uuid
ON
    updates
FOR EACH ROW WHEN
    OLD.uuid != NEW.uuid AND OLD.uuid != ''
BEGIN
    SELECT debug(
        'TRIGGER bu_updates_1',
        OLD.uuid,
        NEW.uuid
    );
    SELECT RAISE(ABORT, 'updates.uuid mismatch');
END;


CREATE TRIGGER
    au_updates_1
AFTER UPDATE OF
    prefix
ON
    updates
FOR EACH ROW
BEGIN

    SELECT debug(
        'TRIGGER au_updates_1',
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
                || substr(uuid,1,2)
            ELSE
                strftime('%Y%j%H%M%S',mtime,'unixepoch')
                || substr(uuid,1,2)
            END
    WHERE
        id = OLD.id
    ;

    /*
        First of all add the parents of the list of projects in
        upate_projects for the current update
    */

    INSERT INTO
        project_related_updates(
            update_id,
            project_id
        )
    SELECT
        NEW.id,
        projects_tree.parent
    FROM
        project_related_updates
    INNER JOIN
        projects_tree
    ON
        projects_tree.child = project_related_updates.project_id
    WHERE
        project_related_updates.update_id = NEW.id
    ;

    /*
        Find the intersection between the projects of this update, and
        the projects of other updates with the same prefix, and update
        the project_prefixes table accordingly.
    */

    INSERT INTO
        project_prefixes(project_id,prefix,hash,num_updates)
    SELECT
        project_id,
        NEW.prefix,
        substr(agg_sha1_hex(update_uuid),1,8) AS hash,
        count(update_uuid) as num_updates
    FROM
        (
        SELECT
            project_related_updates.project_id,
            updates.uuid AS update_uuid
        FROM
            updates
        INNER JOIN
            project_related_updates
        ON
            project_related_updates.update_id = updates.id
        INNER JOIN
            project_related_updates up2
        ON
            up2.update_id = NEW.id AND
            up2.project_id = project_related_updates.project_id
        WHERE
            updates.prefix = NEW.prefix
        ORDER BY
            project_related_updates.project_id,
            updates.uuid
        )
    GROUP BY
        project_id,
        NEW.prefix
    ;

END;
