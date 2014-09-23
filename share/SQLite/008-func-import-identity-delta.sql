CREATE TABLE func_import_identity_delta(
    change_uuid VARCHAR(40) NOT NULL,
    identity_uuid VARCHAR(40) NOT NULL,
    shortname VARCHAR
);

CREATE TRIGGER
    func_import_identity_delta_bi_1
BEFORE INSERT ON
    func_import_identity_delta
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.change_uuid,
        NEW.identity_uuid,
        NEW.shortname
    );

    INSERT INTO
        identity_deltas(
            change_id,
            identity_id,
            shortname
        )
    SELECT
        c.id,
        identities.id,
        NEW.shortname
    FROM
        topics AS identities
    INNER JOIN
        changes c
    ON
        c.uuid = NEW.change_uuid
    WHERE
        identities.uuid = NEW.identity_uuid
    ;

    SELECT RAISE(IGNORE);
END;
