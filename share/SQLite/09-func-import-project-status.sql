CREATE TABLE func_import_project_status(
    update_uuid VARCHAR(40) NOT NULL,
    project_uuid VARCHAR(40) NOT NULL,
    status VARCHAR(40) NOT NULL,
    rank INTEGER NOT NULL
);


CREATE TRIGGER
    bi_func_import_project_status_1
BEFORE INSERT ON
    func_import_project_status
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.update_uuid,
        NEW.project_uuid,
        NEW.status,
        NEW.rank
    );

    INSERT INTO
        func_new_project_status(
            update_id,
            project_id,
            status,
            rank
        )
    SELECT
        u.id,
        projects.id,
        NEW.status,
        NEW.rank
    FROM
        topics AS projects
    INNER JOIN
        updates u
    ON
        u.uuid = NEW.update_uuid
    WHERE
        projects.uuid = NEW.project_uuid
    ;

    SELECT RAISE(IGNORE);
END;
