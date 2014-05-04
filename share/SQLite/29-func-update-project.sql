CREATE TABLE func_update_project(
    update_id INTEGER NOT NULL,
    id INTEGER NOT NULL,
    name VARCHAR(40),
    parent_id INTEGER,
    parent_uuid INTEGER,
    status_id INTEGER,
    status_uuid VARCHAR(40),
    hub_uuid VARCHAR(40),
    title VARCHAR
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
        NEW.hub_uuid,
        NEW.title
    );

    INSERT INTO
        project_updates(
            update_id,
            project_id,
            parent_id,
            name,
            title,
            status_id,
            hub_uuid
        )
    VALUES(
        NEW.update_id,
        NEW.id,
        NEW.parent_id,
        NEW.name,
        NEW.title,
        NEW.status_id,
        NEW.hub_uuid
    );

    SELECT RAISE(IGNORE);

END;
