CREATE TABLE func_import_hub_repo_delta(
    change_uuid VARCHAR(40) NOT NULL,
    hub_uuid VARCHAR(40) NOT NULL,
    hub_repo_uuid VARCHAR(40) NOT NULL,
    location VARCHAR
);


CREATE TRIGGER
    func_import_hub_repo_delta_bi_1
BEFORE INSERT ON
    func_import_hub_repo_delta
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.change_uuid,
        NEW.hub_uuid,
        NEW.hub_repo_uuid,
        NEW.location
    );

    -- TODO: hah - doesn't exist yet and obviously never tested!
    INSERT INTO
        func_change_hub_repo(
            change_id,
            hub_id,
            hub_repo_id,
            location
        )
    SELECT
        c.uuid,
        hub.id,
        hub_repo.id,
        NEW.location
    FROM
        topics AS hub_repo
    INNER JOIN
        changes c
    ON
        c.uuid = NEW.change_uuid
    LEFT JOIN
        topics hub
    ON
        hub.uuid = NEW.hub_uuid
    WHERE
        hub_repo.uuid = NEW.hub_repo_uuid
    ;

    SELECT RAISE(IGNORE);
END;
