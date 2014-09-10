CREATE TABLE update_deltas (
    id INTEGER NOT NULL PRIMARY KEY DEFAULT (nextval('update_order')),
    update_id INTEGER NOT NULL UNIQUE,
    new INTEGER,
    action_format VARCHAR NOT NULL,
    action_topic_id_1 INTEGER,
    action_topic_id_2 INTEGER,
    FOREIGN KEY(update_id) REFERENCES updates(id) ON DELETE CASCADE,
    FOREIGN KEY(action_topic_id_1) REFERENCES topics(id)
        ON DELETE CASCADE,
    FOREIGN KEY(action_topic_id_2) REFERENCES topics(id)
        ON DELETE CASCADE
) WITHOUT ROWID;

CREATE TRIGGER
    update_deltas_ai_1
AFTER INSERT ON
    update_deltas
FOR EACH ROW WHEN
    NEW.new = 1
BEGIN

    SELECT debug(
        'TRIGGER update_deltas_ai_1',
        NEW.update_id,
        NEW.action_topic_id_1,
        NEW.action_topic_id_2
    );

    UPDATE
        updates
    SET
        ucount = ucount + 1,
        action = (
            SELECT
                printf(NEW.action_format, t1.id, t2.id)
            FROM
                (SELECT 1)
            LEFT JOIN
                topics t1
            ON
                t1.id = NEW.action_topic_id_1
            LEFT JOIN
                topics t2
            ON
                t2.id = NEW.action_topic_id_2
        )
    WHERE
        id = NEW.update_id
    ;


    UPDATE
        updates_pending
    SET
        terms = terms || (
            SELECT
                    '  - update_delta:' || x'0A'
                || '      action_format: ' || NEW.action_format || x'0A'
                || '      action_topic_uuid_1: '
                || COALESCE(t1.uuid, '~') || x'0A'
                || '      action_topic_uuid_2: '
                || COALESCE(t2.uuid, '~') || x'0A'
            FROM
                (SELECT 1)
            LEFT JOIN
                topics t1
            ON
                t1.id = NEW.action_topic_id_1
            LEFT JOIN
                topics t2
            ON
                t2.id = NEW.action_topic_id_2
        )
    WHERE
        update_id = NEW.update_id
    ;

END;
