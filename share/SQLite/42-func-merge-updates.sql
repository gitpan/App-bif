CREATE TABLE func_merge_updates(
    merge integer NOT NULL
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

    UPDATE project_mergers          SET resolve = 1;
    UPDATE project_status_mergers   SET resolve = 1;
    UPDATE task_status_mergers      SET resolve = 1;
    UPDATE issue_status_mergers     SET resolve = 1;
    UPDATE task_mergers             SET resolve = 1;
    UPDATE issue_mergers            SET resolve = 1;
    UPDATE project_issues_mergers   SET resolve = 1;

    UPDATE updates_pending          SET resolve = 1;

    SELECT RAISE(IGNORE);
END;
