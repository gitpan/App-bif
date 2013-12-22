CREATE TABLE func_update_project(
    update_id integer NOT NULL DEFAULT (currval('updates')),
    id integer NOT NULL,
    name varchar(40),
    parent_id integer,
    parent_uuid integer,
    status_id integer,
    status_uuid varchar(40),
    title varchar
);

CREATE TRIGGER
    bi_func_update_project_1
BEFORE INSERT ON
    func_update_project
FOR EACH ROW BEGIN

    SELECT debug(
        'TRIGGER bi_func_update_project_1',
        NEW.id,
        NEW.update_id,
        NEW.parent_id,
        NEW.parent_uuid,
        NEW.status_id,
        NEW.status_uuid,
        NEW.title
    );

    INSERT INTO
        project_updates(
            update_id,
            project_id,
            parent_id,
            name,
            title,
            status_id
        )
    VALUES(
        NEW.update_id,
        NEW.id,
        NEW.parent_id,
        NEW.name,
        NEW.title,
        NEW.status_id
    );

    SELECT RAISE(IGNORE);

END;
