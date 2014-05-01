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
        The following updates the projects_merkle table
    */

    UPDATE
        project_related_updates
    SET
        merkled = 1
    WHERE
        merkled = 0
    ;

    /*
        The following updates the hubs_merkle table
    */

    UPDATE
        hub_related_updates
    SET
        merkled = 1
    WHERE
        merkled = 0
    ;


    UPDATE hub_tomerge              SET resolve = 1;
    UPDATE hub_locations_tomerge    SET resolve = 1;
    UPDATE projects_tomerge          SET resolve = 1;
    UPDATE project_status_tomerge   SET resolve = 1;
    UPDATE task_status_tomerge      SET resolve = 1;
    UPDATE issue_status_tomerge     SET resolve = 1;
    UPDATE tasks_tomerge             SET resolve = 1;
    UPDATE issues_tomerge            SET resolve = 1;
    UPDATE project_issues_tomerge   SET resolve = 1;


    SELECT RAISE(IGNORE);

END;
