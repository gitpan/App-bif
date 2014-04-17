CREATE TABLE func_import_project(
    parent_uuid VARCHAR(40),
    name VARCHAR(40) NOT NULL,
    title VARCHAR(1024) NOT NULL
);


CREATE TRIGGER
    bi_func_import_project_1
BEFORE INSERT ON
    func_import_project
FOR EACH ROW
BEGIN

    SELECT debug(
        'TRIGGER bi_func_import_project_1',
        NEW.parent_uuid,
        NEW.name,
        NEW.title
    );

    INSERT INTO
        func_new_project(
            parent_id,
            name,
            title
        )
    SELECT
        parents.id,
        NEW.name,
        NEW.title
    FROM
        (SELECT 1)
    LEFT JOIN
        topics AS parents
    ON
        parents.uuid = NEW.parent_uuid
    ;

    SELECT RAISE(IGNORE);
END;