CREATE TABLE tasks (
    id INTEGER NOT NULL PRIMARY KEY,
    update_id INTEGER NOT NULL,
    status_id INTEGER NOT NULL,
    title VARCHAR(1024) NOT NULL DEFAULT '',
    FOREIGN KEY(id) REFERENCES topics(id) ON DELETE CASCADE,
    FOREIGN KEY(update_id) REFERENCES updates(id) ON DELETE CASCADE,
    FOREIGN KEY(status_id) REFERENCES task_status(id) ON DELETE CASCADE
);


/*
    Used by "list topics", "list tasks"
*/
CREATE INDEX tasks_status_id ON tasks(status_id);

CREATE TRIGGER
    tasks_ad_1
AFTER DELETE ON
    tasks
FOR EACH ROW
BEGIN
    SELECT debug(
        OLD.id,
        OLD.update_id,
        OLD.status_id,
        OLD.title
    );

    DELETE FROM
        topics
    WHERE
        id = OLD.id
    ;

    /*
        The following is necessary, because although FK relationships
        do result in the remove of rows from tasks_tomerge, the
        deletion of rows from task_deltas just inserts more rows.
    */
    DELETE FROM
        tasks_tomerge
    WHERE
        task_id = OLD.id
    ;

END;
