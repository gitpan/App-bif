CREATE TABLE func_import_issue_status(
    project_uuid varchar(40) NOT NULL,
    status varchar(40) NOT NULL,
    rank integer NOT NULL,
    def integer
);


CREATE TRIGGER
    bi_func_import_issue_status_1
BEFORE INSERT ON
    func_import_issue_status
FOR EACH ROW
BEGIN

    SELECT debug(
        'TRIGGER bi_func_import_issue_status_1',
        NEW.project_uuid,
        NEW.status,
        NEW.rank,
        NEW.def
    );

    INSERT INTO
        func_new_issue_status(
            project_id,
            status,
            rank,
            def
        )
    SELECT
        projects.id,
        NEW.status,
        NEW.rank,
        NEW.def
    FROM
        topics AS projects
    WHERE
        projects.uuid = NEW.project_uuid
    ;

    SELECT RAISE(IGNORE);
END;
