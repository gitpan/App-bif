CREATE TABLE func_import_entity(
    update_uuid VARCHAR(40) NOT NULL,
    topic_uuid VARCHAR(40) NOT NULL,
    name VARCHAR NOT NULL
);

CREATE TRIGGER
    func_import_entity_bi_1
BEFORE INSERT ON
    func_import_entity
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.update_uuid,
        NEW.topic_uuid,
        NEW.name
    );

    INSERT INTO
        func_new_entity(
            update_id,
            id,
            name
        )
    SELECT
        u.id,
        t.id,
        NEW.name
    FROM
        updates u
    INNER JOIN
        topics t
    ON
        t.uuid = NEW.topic_uuid
    WHERE
        u.uuid = NEW.update_uuid
    ;

    SELECT RAISE(IGNORE);
END;
