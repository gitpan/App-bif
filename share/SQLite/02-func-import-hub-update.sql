CREATE TABLE func_import_hub_update(
    hub_uuid VARCHAR(40) NOT NULL,
    related_update_uuid VARCHAR(40),
    default_location_uuid VARCHAR(40)
);

CREATE TRIGGER
    bi_func_import_hub_update_1
BEFORE INSERT ON
    func_import_hub_update
FOR EACH ROW
BEGIN

    SELECT debug(
        'TRIGGER bi_func_import_hub_update_1',
        NEW.hub_uuid,
        NEW.related_update_uuid,
        NEW.default_location_uuid
    );

    INSERT INTO
        hub_updates(
            update_id,
            hub_id,
            related_update_uuid,
            default_location_id
        )
    SELECT
        currval('updates'),
        hubs.id,
        NEW.related_update_uuid,
        hl.id
    FROM
        topics AS hubs
    LEFT JOIN
        topics hl
    ON
        hl.uuid = NEW.default_location_uuid
    WHERE
        hubs.uuid = NEW.hub_uuid
    ;

    SELECT RAISE(IGNORE);
END;
