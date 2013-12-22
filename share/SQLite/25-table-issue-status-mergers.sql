CREATE TABLE issue_status_mergers(
    issue_status_id integer NOT NULL UNIQUE,
    parent_id integer DEFAULT 0,
    status integer DEFAULT 0,
    rank integer DEFAULT 0,
    def integer DEFAULT 0,
    resolve integer,
    FOREIGN KEY(issue_status_id) REFERENCES issue_status(id) ON DELETE CASCADE
);

CREATE TRIGGER
    bu_issue_status_mergers_5
BEFORE UPDATE OF
    resolve
ON
    issue_status_mergers
FOR EACH ROW WHEN
    NEW.resolve = 1
BEGIN

    SELECT debug(
        'TRIGGER bu_issue_status_mergers_5',
        OLD.issue_status_id
    );

    UPDATE
        topics
    SET
        mtime = (
            SELECT
                updates.mtime
            FROM
                issue_status_updates
            INNER JOIN
                updates
            ON
                updates.id = issue_status_updates.update_id
            WHERE
                issue_status_updates.issue_status_id =
                    OLD.issue_status_id
            ORDER BY
                updates.mtime DESC,
                updates.uuid
            LIMIT
                1
        )
    WHERE
        id = OLD.issue_status_id
    ;

    DELETE FROM
        issue_status_mergers
    WHERE
        issue_status_id = OLD.issue_status_id
    ;

    SELECT RAISE(IGNORE);

END;

CREATE TRIGGER
    bu_issue_status_mergers_4
BEFORE UPDATE OF
    resolve
ON
    issue_status_mergers
FOR EACH ROW WHEN
    NEW.resolve = 1 AND
    OLD.def != 0
BEGIN

    SELECT debug(
        'TRIGGER bu_issue_status_mergers_4',
        OLD.issue_status_id
    );

    UPDATE
        issue_status
    SET
        def = 1
    WHERE
        id = (
            SELECT
                all_updates.issue_status_id
            FROM
                issue_status_updates
            INNER JOIN
                issue_status
            ON
                issue_status.id = issue_status_updates.issue_status_id
            INNER JOIN
                issue_status AS all_status
            ON
                all_status.project_id = issue_status.project_id
            INNER JOIN
                issue_status_updates AS all_updates
            ON
                all_updates.issue_status_id = all_status.id AND
                all_updates.def = 1
            INNER JOIN
                updates
            ON
                updates.id = all_updates.update_id
            WHERE
                issue_status_updates.issue_status_id = OLD.issue_status_id
            ORDER BY
                updates.mtime DESC,
                updates.uuid
            LIMIT
                1
        )
    ;

END;

CREATE TRIGGER
    bu_issue_status_mergers_3
BEFORE UPDATE OF
    resolve
ON
    issue_status_mergers
FOR EACH ROW WHEN
    NEW.resolve = 1 AND
    OLD.rank != 0
BEGIN

    SELECT debug(
        'TRIGGER bu_issue_status_mergers_3',
        OLD.issue_status_id
    );

    UPDATE
        issue_status
    SET
        rank = (
            SELECT
                issue_status_updates.rank
            FROM
                issue_status_updates
            INNER JOIN
                updates
            ON
                updates.id = issue_status_updates.update_id
            WHERE
                issue_status_updates.issue_status_id = OLD.issue_status_id AND
                issue_status_updates.rank IS NOT NULL
            ORDER BY
                updates.mtime DESC,
                updates.uuid
            LIMIT
                1
        )
    WHERE
        id = OLD.issue_status_id
    ;

END;

CREATE TRIGGER
    bu_issue_status_mergers_1
BEFORE UPDATE OF
    resolve
ON
    issue_status_mergers
FOR EACH ROW WHEN
    NEW.resolve = 1 AND
    OLD.status != 0
BEGIN

    SELECT debug(
        'TRIGGER bu_issue_status_mergers_1',
        OLD.issue_status_id
    );

    UPDATE
        issue_status
    SET
        status = (
            SELECT
                issue_status_updates.status
            FROM
                issue_status_updates
            INNER JOIN
                updates
            ON
                updates.id = issue_status_updates.update_id
            WHERE
                issue_status_updates.issue_status_id =
                    OLD.issue_status_id AND
                issue_status_updates.status IS NOT NULL
            ORDER BY
                updates.mtime DESC,
                updates.uuid
            LIMIT
                1
        )
    WHERE
        id = OLD.issue_status_id
    ;

END;
