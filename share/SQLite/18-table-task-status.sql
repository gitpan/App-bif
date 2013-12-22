CREATE TABLE task_status (
    id integer NOT NULL PRIMARY KEY,
    project_id integer NOT NULL,
    status varchar(40) NOT NULL,
    rank integer NOT NULL,
    def integer,
    FOREIGN KEY (id) REFERENCES topics(id) ON DELETE CASCADE
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    UNIQUE (project_id,status),
    CONSTRAINT def_constraint CHECK (
        def = 1 OR def IS NULL
    )
);

CREATE TRIGGER
    ai_task_status_1
AFTER INSERT ON
    task_status
FOR EACH ROW WHEN
    NEW.def = 1
BEGIN

    SELECT debug(
        NEW.id,
        NEW.project_id,
        NEW.status
    );

    UPDATE
        task_status
    SET
        def = NULL
    WHERE
        project_id = NEW.project_id AND
        def = 1 AND
        id != NEW.id
    ;

END;

CREATE TRIGGER
    au_task_status_1
AFTER UPDATE ON
    task_status
FOR EACH ROW WHEN
    NEW.def = 1 AND OLD.def != 1
BEGIN

    SELECT debug(
        NEW.id,
        NEW.status
    );

    UPDATE
        task_status
    SET
        def = NULL
    WHERE
        project_id = NEW.project_id AND
        def = 1 AND
        id != NEW.id
    ;

END;

CREATE TRIGGER
    ad_task_status_1
AFTER DELETE ON
    task_status
FOR EACH ROW
BEGIN
    SELECT debug(
        OLD.id
    );

    DELETE FROM
        task_status_mergers
    WHERE
        task_status_id = OLD.id
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
