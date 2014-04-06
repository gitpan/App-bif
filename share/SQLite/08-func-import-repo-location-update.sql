CREATE TABLE func_import_repo_location_update(
    repo_location_uuid VARCHAR(40) NOT NULL,
    location VARCHAR
);


CREATE TRIGGER
    bi_func_import_repo_location_update_1
BEFORE INSERT ON
    func_import_repo_location_update
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.repo_location_uuid,
        NEW.location
    );

    INSERT INTO
        func_update_repo_location(
            repo_location_id,
            location
        )
    SELECT
        repo_location.id,
        NEW.location
    FROM
        topics AS repo_location
    WHERE
        repo_location.uuid = NEW.repo_location_uuid
    ;

    SELECT RAISE(IGNORE);
END;
