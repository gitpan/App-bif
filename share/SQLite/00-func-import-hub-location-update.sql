CREATE TABLE func_import_hub_location_update(
    hub_location_uuid VARCHAR(40) NOT NULL,
    location VARCHAR
);


CREATE TRIGGER
    bi_func_import_hub_location_update_1
BEFORE INSERT ON
    func_import_hub_location_update
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.hub_location_uuid,
        NEW.location
    );

    INSERT INTO
        func_update_hub_location(
            hub_location_id,
            location
        )
    SELECT
        hub_location.id,
        NEW.location
    FROM
        topics AS hub_location
    WHERE
        hub_location.uuid = NEW.hub_location_uuid
    ;

    SELECT RAISE(IGNORE);
END;