CREATE TABLE func_import_repo_update(
    repo_uuid VARCHAR(40) NOT NULL,
    related_update_uuid VARCHAR(40),
    default_location_uuid VARCHAR(40)
);

CREATE TRIGGER
    bi_func_import_repo_update_1
BEFORE INSERT ON
    func_import_repo_update
FOR EACH ROW
BEGIN

    SELECT debug(
        'TRIGGER bi_func_import_repo_update_1',
        NEW.repo_uuid,
        NEW.related_update_uuid,
        NEW.default_location_uuid
    );

    INSERT INTO
        repo_updates(
            update_id,
            repo_id,
            related_update_uuid,
            default_location_id
        )
    SELECT
        currval('updates'),
        repos.id,
        NEW.related_update_uuid,
        rl.id
    FROM
        topics AS repos
    LEFT JOIN
        topics rl
    ON
        rl.uuid = NEW.default_location_uuid
    WHERE
        repos.uuid = NEW.repo_uuid
    ;

    SELECT RAISE(IGNORE);
END;
