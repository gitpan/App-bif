CREATE TABLE func_import_project_update(
    project_uuid varchar(40) NOT NULL,
    parent_uuid varchar(40),
    status_uuid varchar(40),
    name varchar(40),
    title varchar(1024)
);


CREATE TRIGGER
    bi_func_import_project_update_1
BEFORE INSERT ON
    func_import_project_update
FOR EACH ROW
BEGIN

    SELECT debug(
        'TRIGGER bi_func_import_project_update_1',
        NEW.project_uuid,
        NEW.parent_uuid,
        NEW.status_uuid,
        NEW.name,
        NEW.title
    );

    INSERT INTO
        func_update_project(
            id,
            parent_id,
            status_id,
            name,
            title
        )
    SELECT
        projects.id,
        parents.id,
        project_status.id,
        NEW.name,
        NEW.title
    FROM
        topics AS projects
    LEFT JOIN
        topics AS parents
    ON
        parents.uuid = NEW.parent_uuid
    LEFT JOIN
        topics AS project_status
    ON
        project_status.uuid = NEW.status_uuid
    WHERE
        projects.uuid = NEW.project_uuid
    ;

    SELECT RAISE(IGNORE);
END;
