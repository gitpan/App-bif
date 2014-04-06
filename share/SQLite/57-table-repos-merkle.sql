CREATE TABLE repos_merkle (
    repo_id INTEGER,
    prefix VARCHAR NOT NULL COLLATE NOCASE,
    hash VARCHAR NOT NULL,
    num_updates INTEGER NOT NULL,
    FOREIGN KEY(repo_id) REFERENCES repos(id)
        ON DELETE CASCADE,
    UNIQUE(repo_id,prefix)
);

-- -----------------------------------------------------------------------
-- When the prefix being inserted is a "leaf" (length of 5) we
-- remove all parent prefixes for this project that contained the
-- old version of this leaf.
-- -----------------------------------------------------------------------
CREATE TRIGGER
    bi_repos_merkle
BEFORE INSERT ON
    repos_merkle
FOR EACH ROW WHEN
    length(NEW.prefix) = 5
BEGIN
    SELECT debug(
        'bi_repos_merkle',
        NEW.repo_id,
        NEW.prefix,
        NEW.hash,
        NEW.num_updates
    );

    -- TODO: check if this fully uses the covering index 
    DELETE FROM
        repos_merkle
    WHERE
        repo_id = NEW.repo_id AND
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
    ai_repos_merkle2
AFTER INSERT ON
    repos_merkle
FOR EACH ROW WHEN
    NEW.num_updates = 0
BEGIN
    SELECT debug(
        'ai_repos_merkle2',
        NEW.repo_id,
        NEW.prefix,
        NEW.hash,
        NEW.num_updates
    );

    DELETE FROM
        repos_merkle
    WHERE
        repo_id = NEW.repo_id AND prefix = NEW.prefix
    ;
END;

-- -----------------------------------------------------------------------
-- When the prefix just inserted was a "leaf" (length of 5) we
-- recalculate all parent prefixes for this project
-- (Remember SQLite triggers are LIFO)
-- -----------------------------------------------------------------------
CREATE TRIGGER
    ai_repos_merkle1
AFTER INSERT ON
    repos_merkle
FOR EACH ROW WHEN
    length(NEW.prefix) = 5
BEGIN
    SELECT debug(
        'ai_repos_merkle1',
        NEW.repo_id,
        NEW.prefix,
        NEW.hash,
        NEW.num_updates
    );

    INSERT INTO
        repos_merkle(repo_id,prefix,hash,num_updates)
    SELECT
        NEW.repo_id,
        substr(NEW.prefix,1,4) as prefix,
        substr(agg_sha1_hex(hash),1,8),
        sum(num_updates) AS sum_num_updates
    FROM
        (SELECT
            hash,num_updates
        FROM
            repos_merkle
        WHERE
            repo_id = NEW.repo_id AND
            prefix LIKE substr(NEW.prefix,1,4) || '_'
        ORDER BY
            prefix
        )
    GROUP BY
        NEW.repo_id,prefix
    HAVING
        sum_num_updates > 0
    ;

    INSERT INTO
        repos_merkle(repo_id,prefix,hash,num_updates)
    SELECT
        NEW.repo_id,
        substr(NEW.prefix,1,3) as prefix,
        substr(agg_sha1_hex(hash),1,8),
        sum(num_updates) AS sum_num_updates
    FROM
        (SELECT
            hash,num_updates
        FROM
            repos_merkle
        WHERE
            repo_id = NEW.repo_id AND
            prefix LIKE substr(NEW.prefix,1,3) || '_'
        ORDER BY
            prefix
        )
    GROUP BY
        NEW.repo_id,prefix
    HAVING
        sum_num_updates > 0
    ;

    INSERT INTO
        repos_merkle(repo_id,prefix,hash,num_updates)
    SELECT
        NEW.repo_id,
        substr(NEW.prefix,1,2) as 'prefix',
        substr(agg_sha1_hex(hash),1,8),
        sum(num_updates) AS sum_num_updates
    FROM
        (SELECT
            hash,num_updates
        FROM
            repos_merkle
        WHERE
            repo_id = NEW.repo_id AND
            prefix LIKE substr(NEW.prefix,1,2) || '_'
        ORDER BY
            prefix
        )
    GROUP BY
        NEW.repo_id,prefix
    HAVING
        sum_num_updates > 0
    ;

    INSERT INTO
        repos_merkle(repo_id,prefix,hash,num_updates)
    SELECT
        NEW.repo_id,
        substr(NEW.prefix,1,1) as 'prefix',
        substr(agg_sha1_hex(hash),1,8),
        sum(num_updates) AS sum_num_updates
    FROM
        (SELECT
            hash,num_updates
        FROM
            repos_merkle
        WHERE
            repo_id = NEW.repo_id AND
            prefix LIKE substr(NEW.prefix,1,1) || '_'
        ORDER BY
            prefix
        )
    GROUP BY
        NEW.repo_id,prefix
    HAVING
        sum_num_updates > 0
    ;

    ----select debug('select * from repos_merkle where
    --repo_id = ? and prefix = ?', NEW.repo_id, NEW.s0);
    UPDATE
        repos
    SET
        hash = (
            SELECT
                substr(agg_sha1_hex(hash),1,8)
            FROM
                (SELECT
                      hash
                FROM
                    repos_merkle
                WHERE
                    repo_id = NEW.repo_id AND
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
                repos_merkle
            WHERE
                repo_id = NEW.repo_id AND
                prefix LIKE '_'
        )
    WHERE
        id = NEW.repo_id
    ;

END;
