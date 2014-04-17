CREATE TABLE repo_related_updates(
    repo_id INTEGER NOT NULL,
    update_id INTEGER NOT NULL,
    merkled INTEGER NOT NULL DEFAULT 0,
    UNIQUE(repo_id,update_id) ON CONFLICT IGNORE,
    CHECK (merkled = 0 OR merkled = 1),
    FOREIGN KEY(repo_id) REFERENCES repos(id) ON DELETE CASCADE,
    FOREIGN KEY(update_id) REFERENCES updates(id) ON DELETE CASCADE
);

/*
    Only need to do this for update_id as the UNIQUE condition above
    should work as a covering index for "WHERE repo_id =" expressions.
*/
CREATE INDEX
    repo_related_updates_update_id
ON
    repo_related_updates(update_id)
;

CREATE TRIGGER
    bi_repo_related_updates
BEFORE INSERT ON
    repo_related_updates
FOR EACH ROW
BEGIN
    SELECT debug(
        'bi_repo_related_updates',
        NEW.repo_id,
        NEW.update_id,
        NEW.merkled
    );

END;

CREATE TRIGGER
    bu_repo_related_updates
BEFORE UPDATE OF
    merkled
ON
    repo_related_updates
FOR EACH ROW WHEN
    NEW.merkled = 1
BEGIN
    SELECT debug(
        'bu_repo_related_updates',
        NEW.repo_id,
        NEW.update_id,
        NEW.merkled
    );

select debug('select id,uuid,prefix from updates');
select debug('select * from repo_related_updates');
select debug('SELECT
            u2.prefix,
            u2.uuid
        FROM
            updates u
        INNER JOIN
            updates u2
        ON
            u2.prefix = u.prefix
        INNER JOIN
            repo_related_updates rru
        ON
            rru.update_id = u2.id AND rru.repo_id = ?
        WHERE
            u.id = ?
',NEW.repo_id,NEW.update_id);
select debug('SELECT
        ?,
        src.prefix,
        substr(agg_sha1_hex(src.uuid),1,8) AS hash,
        count(src.uuid) as num_updates
    FROM
        (
        SELECT
            u2.prefix,
            u2.uuid
        FROM
            updates u
        INNER JOIN
            updates u2
        ON
            u2.prefix = u.prefix
        INNER JOIN
            repo_related_updates rru
        ON
            rru.update_id = u2.id AND rru.repo_id = ?
        WHERE
            u.id = ?
        ) src
    GROUP BY
        ?,
        src.prefix
',NEW.repo_id,NEW.repo_id,NEW.update_id,NEW.repo_id);

    /*
        TODO: write a new agg_sha1_hex_sorted function because the
        following is broken: rows fed to aggregate functions in SQLite
        in arbitrary order.
    */

    INSERT INTO
        repos_merkle(
            repo_id,
            prefix,
            hash,
            num_updates
        )
    SELECT
        NEW.repo_id,
        src.prefix,
        substr(agg_sha1_hex(src.uuid),1,8) AS hash,
        count(src.uuid) as num_updates
    FROM
        (
        SELECT
            u2.prefix,
            u2.uuid
        FROM
            updates u
        INNER JOIN
            updates u2
        ON
            u2.prefix = u.prefix
        INNER JOIN
            repo_related_updates rru
        ON
            rru.update_id = u2.id AND rru.repo_id = NEW.repo_id
        WHERE
            u.id = NEW.update_id
        ) src
    GROUP BY
        NEW.repo_id,
        src.prefix
    ;

END;
