CREATE TABLE func_import_hub_delta(
    update_uuid VARCHAR(40) NOT NULL,
    hub_uuid VARCHAR(40) NOT NULL,
    name VARCHAR(128),
    project_uuid VARCHAR(40)
);

CREATE TRIGGER
    func_import_hub_delta_bi_1
BEFORE INSERT ON
    func_import_hub_delta
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.update_uuid,
        NEW.hub_uuid,
        NEW.name,
        NEW.project_uuid
    );

    INSERT INTO
        hub_deltas(
            update_id,
            hub_id,
            name,
            project_id
        )
    SELECT
        u.id,
        hubs.id,
        NEW.name,
        p.id
    FROM
        topics AS hubs
    INNER JOIN
        updates u
    ON
        u.uuid = NEW.update_uuid
    LEFT JOIN
        topics p
    ON
        p.uuid = NEW.project_uuid
    WHERE
        hubs.uuid = NEW.hub_uuid
    ;

    SELECT RAISE(IGNORE);
END;
