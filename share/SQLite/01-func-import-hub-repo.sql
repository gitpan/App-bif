CREATE TABLE func_import_hub_repo(
    update_uuid VARCHAR(40) NOT NULL,
    hub_uuid VARCHAR(40) NOT NULL,
    location VARCHAR NOT NULL
);


CREATE TRIGGER
    func_import_hub_repo_bi_1
BEFORE INSERT ON
    func_import_hub_repo
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.update_uuid,
        NEW.hub_uuid,
        NEW.location
    );

    INSERT INTO
        func_new_hub_repo(
            update_id,
            hub_id,
            location
        )
    SELECT
        u.id,
        hubs.id,
        NEW.location
    FROM
        topics AS hubs
    INNER JOIN
        updates u
    ON
        u.uuid = NEW.update_uuid
    WHERE
        hubs.uuid = NEW.hub_uuid
    ;

    SELECT RAISE(IGNORE);
END;
