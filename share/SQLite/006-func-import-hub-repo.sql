CREATE TABLE func_import_hub_repo(
    update_uuid VARCHAR(40) NOT NULL,
    topic_uuid VARCHAR(40) NOT NULL,
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
        NEW.topic_uuid,
        NEW.hub_uuid,
        NEW.location
    );

    INSERT INTO
        func_new_hub_repo(
            update_id,
            id,
            hub_id,
            location
        )
    SELECT
        u.id,
        t.id,
        h.id,
        NEW.location
    FROM
        updates u
    INNER JOIN
        topics t
    ON
        t.uuid = NEW.topic_uuid
    INNER JOIN
        topics h
    ON
        h.uuid = NEW.hub_uuid
    WHERE
        u.uuid = NEW.update_uuid
    ;

    SELECT RAISE(IGNORE);
END;
