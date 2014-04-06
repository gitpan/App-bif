CREATE TABLE func_merge_updates(
    merge INTEGER NOT NULL
);

CREATE TRIGGER
    bi_func_merge_updates_1
BEFORE INSERT ON
    func_merge_updates
FOR EACH ROW WHEN
    NEW.merge = 1
BEGIN
    select debug(
        'TRIGGER bi_func_merge_updates_1'
    );

    UPDATE repo_tomerge              SET resolve = 1;
    UPDATE repo_locations_tomerge    SET resolve = 1;
    UPDATE projects_tomerge          SET resolve = 1;
    UPDATE project_status_tomerge   SET resolve = 1;
    UPDATE task_status_tomerge      SET resolve = 1;
    UPDATE issue_status_tomerge     SET resolve = 1;
    UPDATE tasks_tomerge             SET resolve = 1;
    UPDATE issues_tomerge            SET resolve = 1;
    UPDATE project_issues_tomerge   SET resolve = 1;

    UPDATE
        updates_pending
    SET 
        resolve = 1
    WHERE
        resolve IS NULL
    ;

    /*
        Update repos_merkle to account for projects which have been
        added to a repository.

        TODO: write a new agg_sha1_hex_sorted function because the
        following is broken: rows fed to aggregate functions in SQLite
        in arbitrary order.
    */

    INSERT INTO
        repos_merkle(repo_id,prefix,hash,num_updates)
    SELECT
        list_a.repo_id,
        list_a.prefix,
        substr(agg_sha1_hex(list_a.uuid),1,8) AS hash,
        count(list_a.uuid) as num_updates
    FROM
        (
        SELECT
            rru2.repo_id,
            u2.prefix,
            u2.uuid
        FROM
            repo_related_updates rru
        INNER JOIN
            updates u
        ON
            u.id = rru.update_id
        INNER JOIN
            updates u2
        ON
            u2.prefix = u.prefix
        INNER JOIN
            repo_related_updates rru2
        ON
            rru2.update_id = u2.id AND rru2.repo_id = rru.repo_id
        WHERE
            rru.merkled = 0
        ) list_a
    GROUP BY
        list_a.repo_id,
        list_a.prefix
    ;

    UPDATE
        repo_related_updates
    SET
        merkled = 1
    WHERE
        merkled = 0
    ;

    SELECT RAISE(IGNORE);

END;
