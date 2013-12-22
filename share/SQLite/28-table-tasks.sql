CREATE TABLE tasks (
    id integer NOT NULL PRIMARY KEY,
    update_id integer NOT NULL,
    status_id integer NOT NULL,
    title varchar(1024) NOT NULL DEFAULT '',
    FOREIGN KEY(id) REFERENCES topics(id) ON DELETE CASCADE,
    FOREIGN KEY(update_id) REFERENCES updates(id) ON DELETE CASCADE,
    FOREIGN KEY(status_id) REFERENCES task_status(id) ON DELETE CASCADE
);

CREATE TRIGGER
    ad_tasks_1
AFTER DELETE ON
    tasks
FOR EACH ROW
BEGIN
    SELECT debug(
        OLD.id,
        OLD.status_id
    );

    DELETE FROM
        task_mergers
    WHERE
        task_id = OLD.id
    ;

    DELETE FROM
        updates
    WHERE
        id = (
            SELECT
                first_update_id
            FROM
                topics
            WHERE
                id = OLD.id
        )
    ;

END;
