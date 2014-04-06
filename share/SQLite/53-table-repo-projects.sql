CREATE TABLE repo_projects (
    repo_id INTEGER NOT NULL,
    project_id INTEGER NOT NULL,
    FOREIGN KEY(repo_id) REFERENCES repos(id) ON DELETE CASCADE,
    FOREIGN KEY(project_id) REFERENCES projects(id) ON DELETE CASCADE,
    UNIQUE (repo_id, project_id) ON CONFLICT IGNORE
);

CREATE TRIGGER
    bi_repo_projects_1
BEFORE INSERT ON
    repo_projects
FOR EACH ROW WHEN
    (
        SELECT
            count(rp.project_id) != 0
        FROM
            projects p
        LEFT JOIN
            projects p2
        ON
            p2.path = p.path
        LEFT JOIN
            repo_projects rp
        ON
            rp.project_id = p2.id AND
            rp.repo_id = NEW.repo_id
        WHERE
            p.id = NEW.project_id
    )
BEGIN
    SELECT debug(
        'TRIGGER bi_repo_projects_1',
        NEW.project_id,
        NEW.repo_id
    );

    SELECT RAISE(ABORT, 'Project with same path already exists in repository');
END;

CREATE TRIGGER
    ai_repo_projects_1
AFTER INSERT ON
    repo_projects
FOR EACH ROW
BEGIN

    SELECT debug(
        'TRIGGER ai_repo_projects_1',
        NEW.repo_id,
        NEW.project_id
    );

    INSERT INTO
        repo_related_updates(
            repo_id,
            update_id
        )
    SELECT
        NEW.repo_id,
        pru.update_id
    FROM
        project_related_updates pru
    WHERE
        pru.project_id = NEW.project_id AND pru.project_only = 1
    ;

END;

CREATE TRIGGER
    ad_repo_projects_1
AFTER DELETE ON
    repo_projects
FOR EACH ROW WHEN
    (
        SELECT
            COUNT(rp.project_id) = 0
        FROM
            repo_projects rp
        WHERE
            rp.project_id = OLD.project_id
    )
BEGIN

    SELECT debug(
        'TRIGGER ad_repo_projects_1',
        OLD.repo_id,
        OLD.project_id
    );

    DELETE FROM
        projects
    WHERE
        id = OLD.project_id
    ;

END;

