CREATE TABLE func_import_topic(
    change_uuid VARCHAR(40) NOT NULL,
    kind VARCHAR NOT NULL
);

CREATE TRIGGER
    func_import_topic_bi_1
BEFORE INSERT ON
    func_import_topic
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.change_uuid,
        NEW.kind
    );

    INSERT INTO
        func_new_topic(
            change_id,
            kind
        )
    SELECT
        c.id,
        NEW.kind
    FROM
        changes c
    WHERE
        c.uuid = NEW.change_uuid
    ;

    SELECT RAISE(IGNORE);
END;
