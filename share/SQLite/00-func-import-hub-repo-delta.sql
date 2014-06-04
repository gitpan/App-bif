CREATE TABLE func_import_hub_repo_delta(
    update_uuid VARCHAR(40) NOT NULL,
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
        NEW.update_uuid,
        NEW.hub_repo_uuid,
        NEW.location
    );

    -- TODO: hah - doesn't exist yet and obviously never tested!
    INSERT INTO
        func_update_hub_repo(
            update_id,
            hub_repo_id,
            location
        )
    SELECT
        u.uuid,
        hub_repo.id,
        NEW.location
    FROM
        topics AS hub_repo
    INNER JOIN
        updates u
    ON
        u.uuid = NEW.update_uuid
    WHERE
        hub_repo.uuid = NEW.hub_repo_uuid
    ;

    SELECT RAISE(IGNORE);
END;
