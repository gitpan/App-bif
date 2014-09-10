CREATE TABLE func_import_identity_delta(
    update_uuid VARCHAR(40) NOT NULL,
    identity_uuid VARCHAR(40) NOT NULL
);

CREATE TRIGGER
    func_import_identity_delta_bi_1
BEFORE INSERT ON
    func_import_identity_delta
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.update_uuid,
        NEW.identity_uuid
    );

    INSERT INTO
        identity_deltas(
            update_id,
            identity_id
        )
    SELECT
        u.id,
        identities.id
    FROM
        topics AS identities
    INNER JOIN
        updates u
    ON
        u.uuid = NEW.update_uuid
    WHERE
        identities.uuid = NEW.identity_uuid
    ;

    SELECT RAISE(IGNORE);
END;
