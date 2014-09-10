CREATE TABLE func_new_topic(
    update_id INTEGER,
    id INTEGER NOT NULL DEFAULT (nextval('topics')),
    kind VARCHAR
);


CREATE TRIGGER
    func_new_topic_bi_1
BEFORE INSERT ON
    func_new_topic
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.update_id,
        NEW.id,
        NEW.kind
    );

    -- TODO if we ever create topic_deltas then move this into there
    UPDATE
        updates
    SET
        ucount = ucount + 1
    WHERE
        id = NEW.update_id
    ;

    -- TODO if we ever create topic_deltas then move this into there
    UPDATE
        updates_pending
    SET
        terms = terms
            || '  - topic:' || x'0A'
            || '      kind: ' || NEW.kind || x'0A'
    WHERE
        update_id = NEW.update_id
    ;

    INSERT INTO
        topics(
            id,
            first_update_id,
            kind,
            ctime,
            ctimetz,
            mtime,
            mtimetz,
            lang,
            uuid
        )
    SELECT
        NEW.id,
        NEW.update_id,
        NEW.kind,
        u.mtime,
        u.mtimetz,
        u.mtime,
        u.mtimetz,
        u.lang,
        sha1_hex(up.terms)
    FROM
        updates u
    INNER JOIN
        updates_pending up
    ON
        up.update_id = u.id
    WHERE
        u.id = NEW.update_id
    ;

END;
