CREATE TABLE func_import_hub_location_update(
    update_uuid VARCHAR(40) NOT NULL,
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
        NEW.update_uuid,
        NEW.hub_location_uuid,
        NEW.location
    );

    -- TODO: hah - doesn't exist yet and obviously never tested!
    INSERT INTO
        func_update_hub_location(
            update_id,
            hub_location_id,
            location
        )
    SELECT
        u.uuid,
        hub_location.id,
        NEW.location
    FROM
        topics AS hub_location
    INNER JOIN
        updates u
    ON
        u.uuid = NEW.update_uuid
    WHERE
        hub_location.uuid = NEW.hub_location_uuid
    ;

    SELECT RAISE(IGNORE);
END;
