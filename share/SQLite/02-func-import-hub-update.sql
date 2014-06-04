CREATE TABLE func_import_hub_delta(
    update_uuid VARCHAR(40) NOT NULL,
    hub_uuid VARCHAR(40) NOT NULL,
    name VARCHAR(128),
    default_location_uuid VARCHAR(40),
    project_uuid VARCHAR(40),
    related_update_uuid VARCHAR(40)
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
        NEW.default_location_uuid,
        NEW.project_uuid,
        NEW.related_update_uuid
    );

    INSERT INTO
        hub_deltas(
            update_id,
            hub_id,
            name,
            default_location_id,
            project_id,
            related_update_uuid
        )
    SELECT
        u.id,
        hubs.id,
        NEW.name,
        hr.id,
        p.id,
        NEW.related_update_uuid
    FROM
        topics AS hubs
    INNER JOIN
        updates u
    ON
        u.uuid = NEW.update_uuid
    LEFT JOIN
        topics hr
    ON
        hr.uuid = NEW.default_location_uuid
    LEFT JOIN
        topics p
    ON
        p.uuid = NEW.project_uuid
    WHERE
        hubs.uuid = NEW.hub_uuid
    ;

    SELECT RAISE(IGNORE);
END;
