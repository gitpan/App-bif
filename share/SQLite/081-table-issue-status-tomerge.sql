CREATE TABLE issue_status_tomerge(
    issue_status_id INTEGER NOT NULL UNIQUE,
    parent_id INTEGER DEFAULT 0,
    status INTEGER DEFAULT 0,
    rank INTEGER DEFAULT 0,
    def INTEGER DEFAULT 0,
    resolve INTEGER,
    FOREIGN KEY(issue_status_id) REFERENCES issue_status(id) ON DELETE CASCADE
);

CREATE TRIGGER
    issue_status_tomerge_bu_5
BEFORE UPDATE OF
    resolve
ON
    issue_status_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1
BEGIN

    SELECT debug(
        'TRIGGER issue_status_tomerge_bu_5',
        OLD.issue_status_id
    );

    UPDATE
        topics
    SET
        mtime = (
            SELECT
                changes.mtime
            FROM
                issue_status_deltas
            INNER JOIN
                changes
            ON
                changes.id = issue_status_deltas.change_id
            WHERE
                issue_status_deltas.issue_status_id =
                    OLD.issue_status_id
            ORDER BY
                changes.mtime DESC,
                changes.uuid
            LIMIT
                1
        )
    WHERE
        id = OLD.issue_status_id
    ;

    DELETE FROM
        issue_status_tomerge
    WHERE
        issue_status_id = OLD.issue_status_id
    ;

    SELECT RAISE(IGNORE);

END;

CREATE TRIGGER
    issue_status_tomerge_bu_4
BEFORE UPDATE OF
    resolve
ON
    issue_status_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1 AND
    OLD.def != 0
BEGIN

    SELECT debug(
        'TRIGGER issue_status_tomerge_bu_4',
        OLD.issue_status_id
    );

    UPDATE
        issue_status
    SET
        def = 1
    WHERE
        id = (
            SELECT
                all_changes.issue_status_id
            FROM
                issue_status_deltas
            INNER JOIN
                issue_status
            ON
                issue_status.id = issue_status_deltas.issue_status_id
            INNER JOIN
                issue_status AS all_status
            ON
                all_status.project_id = issue_status.project_id
            INNER JOIN
                issue_status_deltas AS all_changes
            ON
                all_changes.issue_status_id = all_status.id AND
                all_changes.def = 1
            INNER JOIN
                changes
            ON
                changes.id = all_changes.change_id
            WHERE
                issue_status_deltas.issue_status_id = OLD.issue_status_id
            ORDER BY
                changes.mtime DESC,
                changes.uuid
            LIMIT
                1
        )
    ;

END;

CREATE TRIGGER
    issue_status_tomerge_bu_3
BEFORE UPDATE OF
    resolve
ON
    issue_status_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1 AND
    OLD.rank != 0
BEGIN

    SELECT debug(
        'TRIGGER issue_status_tomerge_bu_3',
        OLD.issue_status_id
    );

    UPDATE
        issue_status
    SET
        rank = (
            SELECT
                issue_status_deltas.rank
            FROM
                issue_status_deltas
            INNER JOIN
                changes
            ON
                changes.id = issue_status_deltas.change_id
            WHERE
                issue_status_deltas.issue_status_id = OLD.issue_status_id AND
                issue_status_deltas.rank IS NOT NULL
            ORDER BY
                changes.mtime DESC,
                changes.uuid
            LIMIT
                1
        )
    WHERE
        id = OLD.issue_status_id
    ;

END;

CREATE TRIGGER
    issue_status_tomerge_bu_1
BEFORE UPDATE OF
    resolve
ON
    issue_status_tomerge
FOR EACH ROW WHEN
    NEW.resolve = 1 AND
    OLD.status != 0
BEGIN

    SELECT debug(
        'TRIGGER issue_status_tomerge_bu_1',
        OLD.issue_status_id
    );

    UPDATE
        issue_status
    SET
        status = (
            SELECT
                issue_status_deltas.status
            FROM
                issue_status_deltas
            INNER JOIN
                changes
            ON
                changes.id = issue_status_deltas.change_id
            WHERE
                issue_status_deltas.issue_status_id =
                    OLD.issue_status_id AND
                issue_status_deltas.status IS NOT NULL
            ORDER BY
                changes.mtime DESC,
                changes.uuid
            LIMIT
                1
        )
    WHERE
        id = OLD.issue_status_id
    ;

END;
