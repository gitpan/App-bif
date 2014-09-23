CREATE TABLE hub_related_changes(
    hub_id INTEGER NOT NULL,
    change_id INTEGER NOT NULL,
    merkled INTEGER NOT NULL DEFAULT 0,
    UNIQUE(hub_id,change_id) ON CONFLICT IGNORE,
    CHECK (merkled = 0 OR merkled = 1),
    FOREIGN KEY(hub_id) REFERENCES hubs(id) ON DELETE CASCADE,
    FOREIGN KEY(change_id) REFERENCES changes(id) ON DELETE CASCADE
);

/*
    Only need to do this for change_id as the UNIQUE condition above
    should work as a covering index for "WHERE hub_id =" expressions.
*/
CREATE INDEX
    hub_related_changes_change_id
ON
    hub_related_changes(change_id)
;

CREATE TRIGGER
    hub_related_changes_bi_1
BEFORE INSERT ON
    hub_related_changes
FOR EACH ROW
BEGIN
    SELECT debug(
        NEW.hub_id,
        NEW.change_id,
        NEW.merkled
    );

END;


CREATE TRIGGER
    hub_related_changes_ai_1
AFTER INSERT ON
    hub_related_changes
FOR EACH ROW
BEGIN
    SELECT debug(
        NEW.hub_id,
        NEW.change_id
    );

    INSERT INTO
        hub_entities(
            hub_id,
            entity_id
        )
    SELECT
        NEW.hub_id,
        c.identity_id
    FROM
        changes c
    WHERE
        c.id = NEW.change_id
    ;

END;


CREATE TRIGGER
    hub_related_changes_bu_1
BEFORE UPDATE OF
    merkled
ON
    hub_related_changes
FOR EACH ROW WHEN
    NEW.merkled = 1
BEGIN
    SELECT debug(
        'hub_related_changes_bu_1',
        NEW.hub_id,
        NEW.change_id,
        NEW.merkled
    );

    INSERT INTO
        hub_related_changes_merkle(
            hub_id,
            prefix,
            hash,
            num_changes
        )
    SELECT
        NEW.hub_id,
        SUBSTR(src.uuid,1,5),
        substr(agg_sha1_hex(src.uuid, src.uuid),1,8) AS hash,
        count(src.uuid) as num_changes
    FROM
        (
        SELECT
            c2.uuid
        FROM
            changes c
        INNER JOIN
            changes c2
        ON
            c2.uuid LIKE SUBSTR(c.uuid, 1, 5) || '%'
        INNER JOIN
            hub_related_changes hrc
        ON
            hrc.change_id = c2.id AND hrc.hub_id = NEW.hub_id
        WHERE
            c.id = NEW.change_id
        ) src
    GROUP BY
        NEW.hub_id,
        SUBSTR(src.uuid,1,5)
    ;

END;
