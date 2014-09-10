CREATE TABLE func_import_topic(
    update_uuid VARCHAR(40) NOT NULL,
    kind VARCHAR NOT NULL
);

CREATE TRIGGER
    func_import_topic_bi_1
BEFORE INSERT ON
    func_import_topic
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.update_uuid,
        NEW.kind
    );

    INSERT INTO
        func_new_topic(
            update_id,
            kind
        )
    SELECT
        u.id,
        NEW.kind
    FROM
        updates u
    WHERE
        u.uuid = NEW.update_uuid
    ;

    SELECT RAISE(IGNORE);
END;
