CREATE TABLE func_import_hub_location(
    hub_uuid VARCHAR(40) NOT NULL,
    location VARCHAR NOT NULL
);


CREATE TRIGGER
    bi_func_import_hub_location_1
BEFORE INSERT ON
    func_import_hub_location
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.hub_uuid,
        NEW.location
    );

    INSERT INTO
        func_new_hub_location(
            hub_id,
            location
        )
    SELECT
        hubs.id,
        NEW.location
    FROM
        topics AS hubs
    WHERE
        hubs.uuid = NEW.hub_uuid
    ;

    SELECT RAISE(IGNORE);
END;