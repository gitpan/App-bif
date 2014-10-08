CREATE TABLE issue_status (
    id INT NOT NULL PRIMARY KEY,
    project_id INTEGER NOT NULL,
    status VARCHAR(40) NOT NULL,
    rank INTEGER NOT NULL,
    def INTEGER,
    FOREIGN KEY (id) REFERENCES topics(id) ON DELETE CASCADE,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    UNIQUE (project_id,status),
    UNIQUE (id,project_id), -- project_issue has a FK here
    CONSTRAINT def_constraint CHECK (
        def = 1 OR def IS NULL
    )
);

CREATE TRIGGER issue_status_ai_1
AFTER INSERT ON
    issue_status
FOR EACH ROW WHEN
    NEW.def = 1
BEGIN

    SELECT debug(
        NEW.id,
        NEW.project_id,
        NEW.status
    );

    UPDATE
        issue_status
    SET
        def = NULL
    WHERE
        project_id = NEW.project_id AND
        def = 1 AND
        id != NEW.id
    ;

END;

CREATE TRIGGER
    issue_status_au_1
AFTER UPDATE ON
    issue_status
FOR EACH ROW WHEN
    NEW.def = 1 AND OLD.def != 1
BEGIN

    SELECT debug(
        NEW.id,
        NEW.status
    );

    UPDATE
        issue_status
    SET
        def = NULL
    WHERE
        project_id = NEW.project_id AND
        def = 1 AND
        id != NEW.id
    ;

END;

CREATE TRIGGER
    issue_status_ad_1
AFTER DELETE ON
    issue_status
FOR EACH ROW
BEGIN
    SELECT debug(
        OLD.id,
        OLD.status
    );

    /*
        The following is necessary, because although FK relationships
        do result in the remove of rows from issue_status_tomerge, the
        deletion of rows from issue_status_deltas just inserts more
        rows.
    */

    DELETE FROM
        issue_status_tomerge
    WHERE
        issue_status_id = OLD.id
    ;

END;

