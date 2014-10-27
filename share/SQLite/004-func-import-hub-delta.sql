CREATE TABLE func_import_hub_delta(
    change_uuid VARCHAR(40) NOT NULL,
    hub_uuid VARCHAR(40) NOT NULL,
    name VARCHAR(128)
);

CREATE TRIGGER
    func_import_hub_delta_bi_1
BEFORE INSERT ON
    func_import_hub_delta
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.change_uuid,
        NEW.hub_uuid,
        NEW.name
    );

    INSERT INTO
        hub_deltas(
            change_id,
            hub_id,
            name
        )
    SELECT
        c.id,
        hubs.id,
        NEW.name
    FROM
        topics AS hubs
    INNER JOIN
        changes c
    ON
        c.uuid = NEW.change_uuid
    WHERE
        hubs.uuid = NEW.hub_uuid
    ;

    SELECT RAISE(IGNORE);
END;
