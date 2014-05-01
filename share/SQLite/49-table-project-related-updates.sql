CREATE TABLE project_related_updates(
    project_id INTEGER NOT NULL,
    update_id INTEGER NOT NULL,
    project_only INTEGER,
    merkled INTEGER NOT NULL DEFAULT 0,
    CONSTRAINT pru_merkled CHECK (
        merkled = 0 OR merkled = 1
    ),
    CONSTRAINT pru_project_only CHECK (
        project_only = 1 OR project_only IS NULL
    ),
    UNIQUE(update_id,project_id) ON CONFLICT IGNORE
    FOREIGN KEY(update_id) REFERENCES updates(id) ON DELETE CASCADE,
    FOREIGN KEY(project_id) REFERENCES projects(id) ON DELETE CASCADE
);

CREATE INDEX
    project_related_updates_project_id
ON
    project_related_updates(project_id)
;

/*
    If a project has been exported to a hub, then any project-only
    updates must also be recorded as repo-related updates.
*/

CREATE TRIGGER
    ai_project_related_updates
AFTER INSERT ON
    project_related_updates
FOR EACH ROW WHEN
    NEW.project_only = 1
BEGIN
    SELECT debug(
        'ai_project_related_updates',
        NEW.update_id,
        NEW.project_id,
        NEW.project_only
    );

    INSERT INTO
        hub_related_updates(
            hub_id,
            update_id
        )
    SELECT
        p.hub_id,
        NEW.update_id
    FROM
        projects p
    WHERE
        p.id = NEW.project_id AND
        p.hub_id IS NOT NULL
    ;
END;


CREATE TRIGGER
    bu_project_related_updates
BEFORE UPDATE OF
    merkled
ON
    project_related_updates
FOR EACH ROW WHEN
    NEW.merkled = 1
BEGIN
    SELECT debug(
        'bu_project_related_updates',
        NEW.project_id,
        NEW.update_id,
        NEW.merkled
    );

    INSERT INTO
        projects_merkle(
            project_id,
            prefix,
            hash,
            num_updates
        )
    SELECT
        NEW.project_id,
        src.prefix,
        substr(agg_sha1_hex(src.uuid, src.uuid),1,8) AS hash,
        count(src.uuid) as num_updates
    FROM
        (
        SELECT
            u2.prefix,
            u2.uuid
        FROM
            updates u
        INNER JOIN
            updates u2
        ON
            u2.prefix = u.prefix
        INNER JOIN
            project_related_updates pru
        ON
            pru.update_id = u2.id AND pru.project_id = NEW.project_id
        WHERE
            u.id = NEW.update_id
        ) src
    GROUP BY
        NEW.project_id,
        src.prefix
    ;

END;
