CREATE TABLE func_import_project(
    update_uuid VARCHAR(40) NOT NULL,
    parent_uuid VARCHAR(40),
    name VARCHAR(40) NOT NULL,
    title VARCHAR(1024) NOT NULL
);


CREATE TRIGGER
    func_import_project_bi_1
BEFORE INSERT ON
    func_import_project
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.update_uuid,
        NEW.parent_uuid,
        NEW.name,
        NEW.title
    );

    INSERT INTO
        func_new_project(
            update_id,
            parent_id,
            name,
            title
        )
    SELECT
        u.id,
        parents.id,
        NEW.name,
        NEW.title
    FROM
        (SELECT 1)
    INNER JOIN
        updates u
    ON
        u.uuid = NEW.update_uuid
    LEFT JOIN
        topics AS parents
    ON
        parents.uuid = NEW.parent_uuid
    ;

    SELECT RAISE(IGNORE);
END;
