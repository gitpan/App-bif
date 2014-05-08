CREATE TABLE hubs_merkle (
    hub_id INTEGER,
    prefix VARCHAR NOT NULL COLLATE NOCASE,
    hash VARCHAR NOT NULL,
    num_updates INTEGER NOT NULL,
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
    bi_hubs_merkle
BEFORE INSERT ON
    hubs_merkle
FOR EACH ROW WHEN
    length(NEW.prefix) = 5
BEGIN
    SELECT debug(
        'bi_hubs_merkle',
        NEW.hub_id,
        NEW.prefix,
        NEW.hash,
        NEW.num_updates
    );

    -- TODO: check if this fully uses the covering index 
    DELETE FROM
        hubs_merkle
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
-- If a prefix is added with zero updates then remove it
--
-- (Remember SQLite triggers are LIFO)
-- -----------------------------------------------------------------------
CREATE TRIGGER
    ai_hubs_merkle2
AFTER INSERT ON
    hubs_merkle
FOR EACH ROW WHEN
    NEW.num_updates = 0
BEGIN
    SELECT debug(
        'ai_hubs_merkle2',
        NEW.hub_id,
        NEW.prefix,
        NEW.hash,
        NEW.num_updates
    );

    DELETE FROM
        hubs_merkle
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
    ai_hubs_merkle1
AFTER INSERT ON
    hubs_merkle
FOR EACH ROW WHEN
    length(NEW.prefix) = 5
BEGIN
    SELECT debug(
        'ai_hubs_merkle1',
        NEW.hub_id,
        NEW.prefix,
        NEW.hash,
        NEW.num_updates
    );

    INSERT INTO
        hubs_merkle(hub_id,prefix,hash,num_updates)
    SELECT
        NEW.hub_id,
        substr(NEW.prefix,1,4) as prefix,
        substr(agg_sha1_hex(hash, hash),1,8),
        sum(num_updates) AS sum_num_updates
    FROM
        (SELECT
            hash,num_updates
        FROM
            hubs_merkle
        WHERE
            hub_id = NEW.hub_id AND
            prefix LIKE substr(NEW.prefix,1,4) || '_'
        )
    GROUP BY
        NEW.hub_id,prefix
    HAVING
        sum_num_updates > 0
    ;

    INSERT INTO
        hubs_merkle(hub_id,prefix,hash,num_updates)
    SELECT
        NEW.hub_id,
        substr(NEW.prefix,1,3) as prefix,
        substr(agg_sha1_hex(hash, hash),1,8),
        sum(num_updates) AS sum_num_updates
    FROM
        (SELECT
            hash,num_updates
        FROM
            hubs_merkle
        WHERE
            hub_id = NEW.hub_id AND
            prefix LIKE substr(NEW.prefix,1,3) || '_'
        )
    GROUP BY
        NEW.hub_id,prefix
    HAVING
        sum_num_updates > 0
    ;

    INSERT INTO
        hubs_merkle(hub_id,prefix,hash,num_updates)
    SELECT
        NEW.hub_id,
        substr(NEW.prefix,1,2) as prefix,
        substr(agg_sha1_hex(hash, hash),1,8),
        sum(num_updates) AS sum_num_updates
    FROM
        (SELECT
            hash,num_updates
        FROM
            hubs_merkle
        WHERE
            hub_id = NEW.hub_id AND
            prefix LIKE substr(NEW.prefix,1,2) || '_'
        )
    GROUP BY
        NEW.hub_id,prefix
    HAVING
        sum_num_updates > 0
    ;

    INSERT INTO
        hubs_merkle(hub_id,prefix,hash,num_updates)
    SELECT
        NEW.hub_id,
        substr(NEW.prefix,1,1) as prefix,
        substr(agg_sha1_hex(hash, hash),1,8),
        sum(num_updates) AS sum_num_updates
    FROM
        (SELECT
            hash,num_updates
        FROM
            hubs_merkle
        WHERE
            hub_id = NEW.hub_id AND
            prefix LIKE substr(NEW.prefix,1,1) || '_'
        )
    GROUP BY
        NEW.hub_id,prefix
    HAVING
        sum_num_updates > 0
    ;

    ----select debug('select * from hubs_merkle where
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
                    hubs_merkle
                WHERE
                    hub_id = NEW.hub_id AND
                    prefix LIKE '_'
                )
            GROUP BY
                NULL
        ),
        num_updates = (
            SELECT
                sum(num_updates)
            FROM
                hubs_merkle
            WHERE
                hub_id = NEW.hub_id AND
                prefix LIKE '_'
        )
    WHERE
        id = NEW.hub_id
    ;

END;