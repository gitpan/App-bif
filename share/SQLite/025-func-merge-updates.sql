CREATE TABLE func_merge_updates(
    merge INTEGER NOT NULL
);

CREATE TRIGGER
    func_merge_updates_bi_1
BEFORE INSERT ON
    func_merge_updates
FOR EACH ROW WHEN
    NEW.merge = 1
BEGIN

    /*
        The following results in updates.uuid and updates.prefix being
        calculated from all of the *_updates additions to the
        updates_pending table.
    */

    UPDATE
        updates_pending
    SET 
        resolve = 1
    WHERE
        resolve IS NULL
    ;

    /*
        Now that updates.uuid has been set we can run the merge
        operations that use updates.uuid as a sort field
    */

    UPDATE entities_tomerge               SET resolve = 1;
    UPDATE entity_contact_methods_tomerge SET resolve = 1;
    UPDATE hubs_tomerge                   SET resolve = 1;
    UPDATE hub_repos_tomerge              SET resolve = 1;
    UPDATE projects_tomerge               SET resolve = 1;
    UPDATE project_status_tomerge         SET resolve = 1;
    UPDATE task_status_tomerge            SET resolve = 1;
    UPDATE issue_status_tomerge           SET resolve = 1;
    UPDATE tasks_tomerge                  SET resolve = 1;
    UPDATE issues_tomerge                 SET resolve = 1;
    UPDATE project_issues_tomerge         SET resolve = 1;

    /*
        The following updates the hub_related_updates_merkle table
    */

    UPDATE
        hub_related_updates
    SET
        merkled = 1
    WHERE
        merkled = 0
    ;

    /*
        The following updates the project_related_updates_merkle table
    */

    UPDATE
        project_related_updates
    SET
        merkled = 1
    WHERE
        merkled = 0
    ;

    SELECT RAISE(IGNORE);

END;
