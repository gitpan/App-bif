CREATE TABLE hub_related_updates(
    hub_id INTEGER NOT NULL,
    update_id INTEGER NOT NULL,
    merkled INTEGER NOT NULL DEFAULT 0,
    UNIQUE(hub_id,update_id) ON CONFLICT IGNORE,
    CHECK (merkled = 0 OR merkled = 1),
    FOREIGN KEY(hub_id) REFERENCES hubs(id) ON DELETE CASCADE,
    FOREIGN KEY(update_id) REFERENCES updates(id) ON DELETE CASCADE
);

/*
    Only need to do this for update_id as the UNIQUE condition above
    should work as a covering index for "WHERE hub_id =" expressions.
*/
CREATE INDEX
    hub_related_updates_update_id
ON
    hub_related_updates(update_id)
;

CREATE TRIGGER
    hub_related_updates_bi_1
BEFORE INSERT ON
    hub_related_updates
FOR EACH ROW
BEGIN
    SELECT debug(
        NEW.hub_id,
        NEW.update_id,
        NEW.merkled
    );

END;


CREATE TRIGGER
    hub_related_updates_ai_1
AFTER INSERT ON
    hub_related_updates
FOR EACH ROW
BEGIN
    SELECT debug(
        NEW.hub_id,
        NEW.update_id
    );

    INSERT INTO
        hub_entities(
            hub_id,
            entity_id
        )
    SELECT
        NEW.hub_id,
        u.identity_id
    FROM
        updates u
    WHERE
        u.id = NEW.update_id
    ;

END;


CREATE TRIGGER
    hub_related_updates_bu_1
BEFORE UPDATE OF
    merkled
ON
    hub_related_updates
FOR EACH ROW WHEN
    NEW.merkled = 1
BEGIN
    SELECT debug(
        'hub_related_updates_bu_1',
        NEW.hub_id,
        NEW.update_id,
        NEW.merkled
    );

    INSERT INTO
        hub_related_updates_merkle(
            hub_id,
            prefix,
            hash,
            num_updates
        )
    SELECT
        NEW.hub_id,
        src.prefix,
        substr(agg_sha1_hex(src.uuid, src.uuid),1,8) AS hash,
        count(src.uuid) as num_updates
    FROM
        (
        SELECT
            u2.prefix,
            u2.uuid
        FROM
            updates u
        INNER JOIN
            updates u2
        ON
            u2.prefix = u.prefix
        INNER JOIN
            hub_related_updates rru
        ON
            rru.update_id = u2.id AND rru.hub_id = NEW.hub_id
        WHERE
            u.id = NEW.update_id
        ) src
    GROUP BY
        NEW.hub_id,
        src.prefix
    ;

END;
