CREATE TABLE func_import_repo_location(
    repo_uuid VARCHAR(40) NOT NULL,
    location VARCHAR NOT NULL
);


CREATE TRIGGER
    bi_func_import_repo_location_1
BEFORE INSERT ON
    func_import_repo_location
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.repo_uuid,
        NEW.location
    );

    INSERT INTO
        func_new_repo_location(
            repo_id,
            location
        )
    SELECT
        repos.id,
        NEW.location
    FROM
        topics AS repos
    WHERE
        repos.uuid = NEW.repo_uuid
    ;

    SELECT RAISE(IGNORE);
END;
