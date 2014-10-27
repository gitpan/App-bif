CREATE TABLE func_update_project(
    change_id INTEGER NOT NULL,
    id INTEGER NOT NULL,
    name VARCHAR(40),
    parent_id INTEGER,
    parent_uuid INTEGER,
    project_status_id INTEGER,
    status_uuid VARCHAR(40),
    hub_id INTEGER,
    title VARCHAR
);

CREATE TRIGGER
    func_update_project_bi_1
BEFORE INSERT ON
    func_update_project
FOR EACH ROW BEGIN

    SELECT debug(
        'TRIGGER func_update_project_bi_1',
        NEW.id,
        NEW.change_id,
        NEW.parent_id,
        NEW.parent_uuid,
        NEW.project_status_id,
        NEW.status_uuid,
        NEW.hub_id,
        NEW.title
    );

    INSERT INTO
        project_deltas(
            change_id,
            project_id,
            parent_id,
            name,
            title,
            project_status_id,
            hub_id
        )
    VALUES(
        NEW.change_id,
        NEW.id,
        NEW.parent_id,
        NEW.name,
        NEW.title,
        NEW.project_status_id,
        NEW.hub_id
    );

    SELECT RAISE(IGNORE);

END;
