CREATE TABLE issue_updates (
    id INTEGER NOT NULL PRIMARY KEY DEFAULT (nextval('update_order')),
    update_id INTEGER NOT NULL,
    new INTEGER,
    issue_id INTEGER NOT NULL,
    project_id INTEGER NOT NULL,
    status_id INTEGER,
    title VARCHAR(1024),
    FOREIGN KEY(update_id) REFERENCES updates(id) ON DELETE CASCADE,
    FOREIGN KEY(issue_id) REFERENCES issues(id) ON DELETE CASCADE,
    FOREIGN KEY(project_id) REFERENCES projects(id) ON DELETE CASCADE,
    FOREIGN KEY(status_id) REFERENCES issue_status(id) ON DELETE CASCADE--,
    -- Also do a foreign key across project_id/status_id?
--    UNIQUE (update_id,status_id) -- issues FK to this
) WITHOUT ROWID;

CREATE INDEX
    issue_updates_issue_id_status_id
ON
    issue_updates(issue_id,status_id)
;

CREATE TRIGGER
    ai_issue_updates_2
AFTER INSERT ON
    issue_updates
FOR EACH ROW WHEN
    NEW.status_id IS NOT NULL
BEGIN

    SELECT debug(
        'TRIGGER ai_issue_updates_2',
        NEW.update_id,
        NEW.issue_id,
        NEW.project_id,
        NEW.status_id,
        NEW.title
    );

    INSERT OR IGNORE INTO
        project_issues_tomerge(issue_id, project_id)
    VALUES(
        NEW.issue_id,
        NEW.project_id
    );

END;

CREATE TRIGGER
    ai_issue_updates_1
AFTER INSERT ON
    issue_updates
FOR EACH ROW
BEGIN

    SELECT debug(
        'TRIGGER ai_issue_updates_1',
        NEW.update_id,
        NEW.issue_id,
        NEW.status_id,
        NEW.title
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
                'issue_update:' || x'0A'
                || '  issue_uuid:' || COALESCE(topics.uuid, '') || x'0A'
                || '  project_uuid:' || COALESCE(projects.uuid, '') || x'0A'
                || '  status_uuid:' || COALESCE(status.uuid, '') || x'0A'
                || '  title:' || COALESCE(NEW.title, '') || x'0A'
            FROM
                topics
            INNER JOIN
                topics AS projects
            ON
                projects.id = NEW.project_id
            LEFT JOIN
                topics AS status
            ON
                status.id = NEW.status_id
            WHERE
                topics.id = NEW.issue_id
        )
    WHERE
        update_id = NEW.update_id
    ;

    INSERT INTO
        project_related_updates(
            update_id,
            project_id
        )
    SELECT -- This catches the existing projects for the issue
        NEW.update_id,
        project_id
    FROM
        project_issues
    WHERE
        project_issues.issue_id = NEW.issue_id
    UNION SELECT   -- This catches the (possibly new) project of this update
        NEW.update_id,
        NEW.project_id
    ;

    INSERT OR IGNORE INTO
        issues_tomerge(issue_id)
    VALUES
        (NEW.issue_id)
    ;

    UPDATE
        issues_tomerge
    SET
        title = title + (NEW.title IS NOT NULL)
    WHERE
        issue_id = NEW.issue_id
    ;

END;

CREATE TRIGGER
    ad_issue_updates_2
AFTER DELETE ON
    issue_updates
FOR EACH ROW WHEN
    OLD.status_id IS NOT NULL
BEGIN

    SELECT debug(
        OLD.update_id,
        OLD.issue_id,
        OLD.status_id,
        OLD.title
    );

    INSERT OR IGNORE INTO
        project_issues_tomerge(
            issue_id,
            project_id
        )
    VALUES(
        OLD.issue_id,
        OLD.project_id
    );

END;


CREATE TRIGGER
    ad_issue_updates_1
AFTER DELETE ON
    issue_updates
FOR EACH ROW
BEGIN

    SELECT debug(
        OLD.update_id,
        OLD.issue_id,
        OLD.status_id,
        OLD.title
    );

    INSERT OR IGNORE INTO
        issues_tomerge(issue_id)
    VALUES
        (OLD.issue_id)
    ;

    UPDATE
        issues_tomerge
    SET
        title    = title + (OLD.title IS NOT NULL)
    WHERE
        issue_id = OLD.issue_id
    ;

END;
