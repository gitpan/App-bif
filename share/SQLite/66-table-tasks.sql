CREATE TABLE tasks (
    id INTEGER NOT NULL PRIMARY KEY,
    update_id INTEGER NOT NULL,
    status_id INTEGER NOT NULL,
    title VARCHAR(1024) NOT NULL DEFAULT '',
    FOREIGN KEY(id) REFERENCES topics(id) ON DELETE CASCADE,
    FOREIGN KEY(update_id) REFERENCES updates(id) ON DELETE CASCADE,
    FOREIGN KEY(status_id) REFERENCES task_status(id) ON DELETE CASCADE
);

CREATE TRIGGER
    tasks_ad_1
AFTER DELETE ON
    tasks
FOR EACH ROW
BEGIN
    SELECT debug(
        OLD.id,
        OLD.status_id
    );

    DELETE FROM
        tasks_tomerge
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
