CREATE TABLE project_prefixes (
    project_id integer,
    prefix varchar NOT NULL,
    hash varchar NOT NULL,
    num_updates integer NOT NULL,
    FOREIGN KEY(project_id) REFERENCES projects(id)
        ON DELETE CASCADE,
    UNIQUE(project_id,prefix)
);

-- -----------------------------------------------------------------------
-- When the prefix being inserted is a "leaf" (length of 5) we
-- remove all parent prefixes for this project that contained the
-- old version of this leaf.
-- -----------------------------------------------------------------------
CREATE TRIGGER
    bi_project_prefixes
BEFORE INSERT ON
    project_prefixes
FOR EACH ROW WHEN
    length(NEW.prefix) = 5
BEGIN
    SELECT debug(
        'bi_project_prefixes',
        NEW.project_id,
        NEW.prefix,
        NEW.hash,
        NEW.num_updates
    );

    DELETE FROM
        project_prefixes
    WHERE
        project_id = NEW.project_id AND
        prefix IN (
            substr(NEW.prefix,1,1),
            substr(NEW.prefix,1,2),
            substr(NEW.prefix,1,3),
            substr(NEW.prefix,1,4),
            NEW.prefix
        )
    ;
END;

-- -----------------------------------------------------------------------
-- If a prefix is added with zero updates then remove it
--
-- (Remember SQLite triggers are LIFO)
-- -----------------------------------------------------------------------
CREATE TRIGGER
    ai_project_prefixes2
AFTER INSERT ON
    project_prefixes
FOR EACH ROW WHEN
    NEW.num_updates = 0
BEGIN
    SELECT debug(
        'ai_project_prefixes2',
        NEW.project_id,
        NEW.prefix,
        NEW.hash,
        NEW.num_updates
    );

    DELETE FROM
        project_prefixes
    WHERE
        project_id = NEW.project_id AND prefix = NEW.prefix
    ;
END;

-- -----------------------------------------------------------------------
-- When the prefix just inserted was a "leaf" (length of 5) we
-- recalculate all parent prefixes for this project
-- (Remember SQLite triggers are LIFO)
-- -----------------------------------------------------------------------
CREATE TRIGGER
    ai_project_prefixes1
AFTER INSERT ON
    project_prefixes
FOR EACH ROW WHEN
    length(NEW.prefix) = 5
BEGIN
    SELECT debug(
        'ai_project_prefixes1',
        NEW.project_id,
        NEW.prefix,
        NEW.hash,
        NEW.num_updates
    );

    INSERT INTO
        project_prefixes(project_id,prefix,hash,num_updates)
    SELECT
        NEW.project_id,
        substr(NEW.prefix,1,4) as prefix,
        substr(agg_sha1_hex(hash),1,8),
        sum(num_updates) AS sum_num_updates
    FROM
        (SELECT
            hash,num_updates
        FROM
            project_prefixes
        WHERE
            project_id = NEW.project_id AND
            prefix LIKE substr(NEW.prefix,1,4) || '_'
        ORDER BY
            prefix
        )
    GROUP BY
        NEW.project_id,prefix
    HAVING
        sum_num_updates > 0
    ;

    INSERT INTO
        project_prefixes(project_id,prefix,hash,num_updates)
    SELECT
        NEW.project_id,
        substr(NEW.prefix,1,3) as prefix,
        substr(agg_sha1_hex(hash),1,8),
        sum(num_updates) AS sum_num_updates
    FROM
        (SELECT
            hash,num_updates
        FROM
            project_prefixes
        WHERE
            project_id = NEW.project_id AND
            prefix LIKE substr(NEW.prefix,1,3) || '_'
        ORDER BY
            prefix
        )
    GROUP BY
        NEW.project_id,prefix
    HAVING
        sum_num_updates > 0
    ;

    INSERT INTO
        project_prefixes(project_id,prefix,hash,num_updates)
    SELECT
        NEW.project_id,
        substr(NEW.prefix,1,2) as 'prefix',
        substr(agg_sha1_hex(hash),1,8),
        sum(num_updates) AS sum_num_updates
    FROM
        (SELECT
            hash,num_updates
        FROM
            project_prefixes
        WHERE
            project_id = NEW.project_id AND
            prefix LIKE substr(NEW.prefix,1,2) || '_'
        ORDER BY
            prefix
        )
    GROUP BY
        NEW.project_id,prefix
    HAVING
        sum_num_updates > 0
    ;

    INSERT INTO
        project_prefixes(project_id,prefix,hash,num_updates)
    SELECT
        NEW.project_id,
        substr(NEW.prefix,1,1) as 'prefix',
        substr(agg_sha1_hex(hash),1,8),
        sum(num_updates) AS sum_num_updates
    FROM
        (SELECT
            hash,num_updates
        FROM
            project_prefixes
        WHERE
            project_id = NEW.project_id AND
            prefix LIKE substr(NEW.prefix,1,1) || '_'
        ORDER BY
            prefix
        )
    GROUP BY
        NEW.project_id,prefix
    HAVING
        sum_num_updates > 0
    ;

    ----select debug('select * from project_prefixes where
    --project_id = ? and prefix = ?', NEW.project_id, NEW.s0);
    UPDATE
        topics
    SET
        hash = (
            SELECT
                substr(agg_sha1_hex(hash),1,8)
            FROM
                (SELECT
                      hash
                FROM
                    project_prefixes
                WHERE
                    project_id = NEW.project_id AND
                    prefix LIKE '_'
                ORDER BY
                    prefix
                )
            GROUP BY
                NULL
        ),
        num_updates = (
            SELECT
                sum(num_updates)
            FROM
                project_prefixes
            WHERE
                project_id = NEW.project_id AND
                prefix LIKE '_'
        )
    WHERE
        id = NEW.project_id
    ;

END;
