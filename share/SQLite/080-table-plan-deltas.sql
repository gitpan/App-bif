CREATE TABLE plan_deltas (
    id INTEGER NOT NULL PRIMARY KEY DEFAULT (nextval('update_order')),
    update_id INTEGER NOT NULL,
    plan_id INTEGER NOT NULL,
    name VARCHAR,
    title VARCHAR,
    new INTEGER,
    add_remove INTEGER CHECK( add_remove BETWEEN 0 AND 1 ),
    host_id INTEGER,
    FOREIGN KEY(update_id) REFERENCES updates(id) ON DELETE CASCADE,
    FOREIGN KEY(plan_id) REFERENCES plans(id) ON DELETE CASCADE,
    FOREIGN KEY(host_id) REFERENCES hosts(id) ON DELETE CASCADE
) WITHOUT ROWID;

CREATE TRIGGER
    plan_deltas_ai_3
AFTER INSERT ON
    plan_deltas
FOR EACH ROW WHEN
    NEW.add_remove = 0
BEGIN

    SELECT debug(
        NEW.update_id,
        NEW.plan_id,
        NEW.name,
        NEW.title,
        NEW.add_remove,
        NEW.host_id
    );

    DELETE FROM
        plan_hosts
    WHERE
        plan_id = NEW.plan_id AND
        host_id = NEW.host_id
    ;

END;


CREATE TRIGGER
    plan_deltas_ai_2
AFTER INSERT ON
    plan_deltas
FOR EACH ROW WHEN
    NEW.add_remove = 1
BEGIN

    SELECT debug(
        NEW.update_id,
        NEW.plan_id,
        NEW.name,
        NEW.title,
        NEW.add_remove,
        NEW.host_id
    );

    INSERT INTO
        plan_hosts(
            plan_id,
            host_id
        )
    VALUES(
        NEW.plan_id,
        NEW.host_id
    );

END;


CREATE TRIGGER
    plan_deltas_ai_1
AFTER INSERT ON
    plan_deltas
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.update_id,
        NEW.plan_id,
        NEW.name,
        NEW.title,
        NEW.add_remove,
        NEW.host_id
    );

    UPDATE
        updates
    SET
        ucount = ucount + 1
    WHERE
        id = NEW.update_id
    ;

    UPDATE
        updates_pending
    SET
        terms = terms || (
            SELECT
                CASE WHEN
                    NEW.new
                THEN
                    '  - plan:' || x'0A'
                ELSE
                    '  - plan_delta:' || x'0A'
                END
                || '      add_remove: '
                || COALESCE(NEW.add_remove,'~') || x'0A'
                || '      host_uuid: ' || COALESCE(h.uuid,'~') || x'0A'
                || '      name: ' || COALESCE(NEW.name,'~') || x'0A'
                || CASE WHEN
                    NEW.new
                THEN
                    ''
                ELSE
                    '      plan_uuid: ' || topics.uuid || x'0A'
                END
                || '      title: ' || COALESCE(NEW.title, '~') || x'0A'
                || CASE WHEN
                    NEW.new
                THEN
                    '      topic_uuid: ' || topics.uuid || x'0A'
                ELSE
                    ''
                END
            FROM
                topics
            LEFT JOIN
                topics h
            ON
                h.id = NEW.host_id
            WHERE
                topics.id = NEW.plan_id
        )
    WHERE
        update_id = NEW.update_id
    ;

/*
    INSERT INTO
        entity_related_updates(
            entity_id,
            update_id
        )
    VALUES (
        NEW.plan_id,
        NEW.update_id
    );
*/

END;
