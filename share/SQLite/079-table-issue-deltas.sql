CREATE TABLE issue_deltas (
    id INT NOT NULL PRIMARY KEY DEFAULT (nextval('deltas')),
    change_id INTEGER NOT NULL,
    new INTEGER,
    issue_id INTEGER NOT NULL,
    project_id INTEGER NOT NULL,
    issue_status_id INTEGER,
    title VARCHAR(1024),
    FOREIGN KEY(change_id) REFERENCES changes(id) ON DELETE CASCADE,
    FOREIGN KEY(issue_id) REFERENCES issues(id) ON DELETE CASCADE,
    FOREIGN KEY(project_id) REFERENCES projects(id) ON DELETE CASCADE,
    FOREIGN KEY(issue_status_id) REFERENCES issue_status(id) ON DELETE CASCADE
);

CREATE INDEX
    issue_deltas_issue_id_issue_status_id
ON
    issue_deltas(issue_id,issue_status_id)
;

CREATE TRIGGER
    issue_deltas_ai_2
AFTER INSERT ON
    issue_deltas
FOR EACH ROW WHEN
    NEW.issue_status_id IS NOT NULL
BEGIN

    SELECT debug(
        'TRIGGER issue_deltas_ai_2',
        NEW.change_id,
        NEW.issue_id,
        NEW.project_id,
        NEW.issue_status_id,
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
    issue_deltas_ai_1
AFTER INSERT ON
    issue_deltas
FOR EACH ROW
BEGIN

    SELECT debug(
        'TRIGGER issue_deltas_ai_1',
        NEW.change_id,
        NEW.issue_id,
        NEW.issue_status_id,
        NEW.title
    );

    UPDATE
        changes
    SET
        ucount = ucount + 1
    WHERE
        id = NEW.change_id
    ;

    UPDATE
        topics
    SET
        last_change_id = NEW.change_id
    WHERE
        id = NEW.issue_id
    ;

    UPDATE
        changes_pending
    SET
        terms = terms || (
            SELECT
                '-' || x'0A'
                || CASE WHEN
                    NEW.new
                THEN
                    '  _: issue' || x'0A'
                    || '  issue_status_uuid: '
                    || COALESCE(status.uuid, '~') || x'0A'
                ELSE
                    '  _: issue_delta' || x'0A'
                    || '  issue_status_uuid: '
                    || COALESCE(status.uuid, '~') || x'0A'
                    || '  issue_uuid: ' || topics.uuid || x'0A'
                    || '  project_uuid: '
                        || COALESCE(projects.uuid, '~') || x'0A'
                END
                || CASE WHEN
                    instr(NEW.title, ' ')
                THEN
                    '  title: ''' || NEW.title || '''' || x'0A'
                ELSE
                    '  title: ' 
                    || COALESCE(NEW.title,'~') || x'0A'
                END
                || CASE WHEN
                    NEW.new
                THEN
                    '  topic_uuid: ' || topics.uuid || x'0A'
                ELSE
                    ''
                END
            FROM
                topics
            INNER JOIN
                topics AS projects
            ON
                projects.id = NEW.project_id
            LEFT JOIN
                topics AS status
            ON
                status.id = NEW.issue_status_id
            WHERE
                topics.id = NEW.issue_id
        )
    WHERE
        change_id = NEW.change_id
    ;

    INSERT INTO
        project_related_changes(
            project_id,
            real_project_id,
            change_id
        )
    SELECT -- This catches the existing projects for the issue
        pi.project_id,
        NEW.project_id,
        NEW.change_id
    FROM
        project_issues pi
    WHERE
        pi.issue_id = NEW.issue_id
    UNION SELECT   -- This catches the (possibly new) project of this change
        NEW.project_id,
        NEW.project_id,
        NEW.change_id
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
    issue_deltas_ad_2
AFTER DELETE ON
    issue_deltas
FOR EACH ROW WHEN
    OLD.issue_status_id IS NOT NULL
BEGIN

    SELECT debug(
        OLD.change_id,
        OLD.issue_id,
        OLD.issue_status_id,
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
    issue_deltas_ad_1
AFTER DELETE ON
    issue_deltas
FOR EACH ROW
BEGIN

    SELECT debug(
        OLD.change_id,
        OLD.issue_id,
        OLD.issue_status_id,
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
