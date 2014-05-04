CREATE TABLE func_import_hub_update(
    update_uuid VARCHAR(40) NOT NULL,
    hub_uuid VARCHAR(40) NOT NULL,
    default_location_uuid VARCHAR(40),
    project_uuid VARCHAR(40),
    related_update_uuid VARCHAR(40)
);

CREATE TRIGGER
    bi_func_import_hub_update_1
BEFORE INSERT ON
    func_import_hub_update
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.update_uuid,
        NEW.hub_uuid,
        NEW.default_location_uuid,
        NEW.project_uuid,
        NEW.related_update_uuid
    );

    INSERT INTO
        hub_updates(
            update_id,
            hub_id,
            default_location_id,
            project_id,
            related_update_uuid
        )
    SELECT
        u.id,
        hubs.id,
        hl.id,
        p.id,
        NEW.related_update_uuid
    FROM
        topics AS hubs
    INNER JOIN
        updates u
    ON
        u.uuid = NEW.update_uuid
    LEFT JOIN
        topics hl
    ON
        hl.uuid = NEW.default_location_uuid
    LEFT JOIN
        topics p
    ON
        p.uuid = NEW.project_uuid
    WHERE
        hubs.uuid = NEW.hub_uuid
    ;

    SELECT RAISE(IGNORE);
END;
