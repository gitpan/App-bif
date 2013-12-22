CREATE TABLE projects (
    id integer NOT NULL PRIMARY KEY,
    parent_id integer,
    name varchar(40) NOT NULL,
    title varchar(1024) NOT NULL,
    path varchar collate nocase UNIQUE,
    status_id integer NOT NULL DEFAULT -1,
    FOREIGN KEY(id) REFERENCES topics(id)
        ON DELETE CASCADE
    FOREIGN KEY(parent_id) REFERENCES projects(id)
        ON DELETE CASCADE,
    FOREIGN KEY(status_id,id) REFERENCES project_status(id,project_id)
        DEFERRABLE INITIALLY DEFERRED
);

CREATE TRIGGER
    bd_projects_1
BEFORE DELETE ON
    projects
FOR EACH ROW
BEGIN
    SELECT debug(
        OLD.id
    );
--    select debug('select * from topics where id=?', OLD.status_id);
--    select debug('select ?', OLD.status_id);
END;

CREATE TRIGGER
    ad_projects_1
AFTER DELETE ON
    projects
FOR EACH ROW
BEGIN
    SELECT debug(
        OLD.id
    );

    DELETE FROM
        project_mergers
    WHERE
        project_id = OLD.id
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
