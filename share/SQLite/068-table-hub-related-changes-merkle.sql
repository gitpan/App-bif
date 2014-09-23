CREATE TABLE hub_related_changes_merkle (
    hub_id INTEGER,
    prefix VARCHAR NOT NULL COLLATE NOCASE,
    hash VARCHAR NOT NULL,
    num_changes INTEGER NOT NULL,
    FOREIGN KEY(hub_id) REFERENCES hubs(id)
        ON DELETE CASCADE,
    UNIQUE(hub_id,prefix)
);

-- -----------------------------------------------------------------------
-- When the prefix being inserted is a "leaf" (length of 5) we
-- remove all parent prefixes for this project that contained the
-- old version of this leaf.
-- -----------------------------------------------------------------------
CREATE TRIGGER
    hub_related_changes_merkle_bi_1
BEFORE INSERT ON
    hub_related_changes_merkle
FOR EACH ROW WHEN
    length(NEW.prefix) = 5
BEGIN
    SELECT debug(
        'hub_related_changes_merkle_bi_1',
        NEW.hub_id,
        NEW.prefix,
        NEW.hash,
        NEW.num_changes
    );

    -- TODO: check if this fully uses the covering index 
    DELETE FROM
        hub_related_changes_merkle
    WHERE
        hub_id = NEW.hub_id AND
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
-- If a prefix is added with zero changes then remove it
--
-- (Remember SQLite triggers are LIFO)
-- -----------------------------------------------------------------------
CREATE TRIGGER
    hub_related_changes_merkle_ai_2
AFTER INSERT ON
    hub_related_changes_merkle
FOR EACH ROW WHEN
    NEW.num_changes = 0
BEGIN
    SELECT debug(
        'hub_related_changes_merkle_ai_2',
        NEW.hub_id,
        NEW.prefix,
        NEW.hash,
        NEW.num_changes
    );

    DELETE FROM
        hub_related_changes_merkle
    WHERE
        hub_id = NEW.hub_id AND prefix = NEW.prefix
    ;
END;

-- -----------------------------------------------------------------------
-- When the prefix just inserted was a "leaf" (length of 5) we
-- recalculate all parent prefixes for this project
-- (Remember SQLite triggers are LIFO)
-- -----------------------------------------------------------------------
CREATE TRIGGER
    hub_related_changes_merkle_ai_1
AFTER INSERT ON
    hub_related_changes_merkle
FOR EACH ROW WHEN
    length(NEW.prefix) = 5
BEGIN
    SELECT debug(
        'hub_related_changes_merkle_ai_1',
        NEW.hub_id,
        NEW.prefix,
        NEW.hash,
        NEW.num_changes
    );

    INSERT INTO
        hub_related_changes_merkle(hub_id,prefix,hash,num_changes)
    SELECT
        NEW.hub_id,
        substr(NEW.prefix,1,4) as prefix,
        substr(agg_sha1_hex(hash, hash),1,8),
        sum(num_changes) AS sum_num_changes
    FROM
        (SELECT
            hash,num_changes
        FROM
            hub_related_changes_merkle
        WHERE
            hub_id = NEW.hub_id AND
            prefix LIKE substr(NEW.prefix,1,4) || '_'
        )
    GROUP BY
        NEW.hub_id,prefix
    HAVING
        sum_num_changes > 0
    ;

    INSERT INTO
        hub_related_changes_merkle(hub_id,prefix,hash,num_changes)
    SELECT
        NEW.hub_id,
        substr(NEW.prefix,1,3) as prefix,
        substr(agg_sha1_hex(hash, hash),1,8),
        sum(num_changes) AS sum_num_changes
    FROM
        (SELECT
            hash,num_changes
        FROM
            hub_related_changes_merkle
        WHERE
            hub_id = NEW.hub_id AND
            prefix LIKE substr(NEW.prefix,1,3) || '_'
        )
    GROUP BY
        NEW.hub_id,prefix
    HAVING
        sum_num_changes > 0
    ;

    INSERT INTO
        hub_related_changes_merkle(hub_id,prefix,hash,num_changes)
    SELECT
        NEW.hub_id,
        substr(NEW.prefix,1,2) as prefix,
        substr(agg_sha1_hex(hash, hash),1,8),
        sum(num_changes) AS sum_num_changes
    FROM
        (SELECT
            hash,num_changes
        FROM
            hub_related_changes_merkle
        WHERE
            hub_id = NEW.hub_id AND
            prefix LIKE substr(NEW.prefix,1,2) || '_'
        )
    GROUP BY
        NEW.hub_id,prefix
    HAVING
        sum_num_changes > 0
    ;

    INSERT INTO
        hub_related_changes_merkle(hub_id,prefix,hash,num_changes)
    SELECT
        NEW.hub_id,
        substr(NEW.prefix,1,1) as prefix,
        substr(agg_sha1_hex(hash, hash),1,8),
        sum(num_changes) AS sum_num_changes
    FROM
        (SELECT
            hash,num_changes
        FROM
            hub_related_changes_merkle
        WHERE
            hub_id = NEW.hub_id AND
            prefix LIKE substr(NEW.prefix,1,1) || '_'
        )
    GROUP BY
        NEW.hub_id,prefix
    HAVING
        sum_num_changes > 0
    ;

    ----select debug('select * from hub_related_changes_merkle where
    --hub_id = ? and prefix = ?', NEW.hub_id, NEW.s0);
    UPDATE
        hubs
    SET
        hash = (
            SELECT
                substr(agg_sha1_hex(hash, hash),1,8)
            FROM
                (SELECT
                      hash
                FROM
                    hub_related_changes_merkle
                WHERE
                    hub_id = NEW.hub_id AND
                    prefix LIKE '_'
                )
            GROUP BY
                NULL
        ),
        num_changes = (
            SELECT
                sum(num_changes)
            FROM
                hub_related_changes_merkle
            WHERE
                hub_id = NEW.hub_id AND
                prefix LIKE '_'
        )
    WHERE
        id = NEW.hub_id
    ;

END;
