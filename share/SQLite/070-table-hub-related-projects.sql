/*
    Why not just rely on projects.hub_id to keep track of hub/project
    relationships? Because in hub A we also want to store/refer to
    projects that are hosted at hub B, in which case hub B's changes
    would not be added to hub A's hub_related_projects table.

    What probably would be smart is to use the projects.hub_id
    relationship anyway, and only use the hub_related_projects table
    for "external" projects.

    2014-10-20 converted to projects.hub_id, but still need to think
    about hub_related_projects for external projects.
*/

CREATE TABLE hub_related_projects(
    hub_id INTEGER NOT NULL,
    project_id INTEGER NOT NULL,
    hash VARCHAR(8) NOT NULL DEFAULT '',
    UNIQUE(hub_id,project_id),
    FOREIGN KEY(hub_id) REFERENCES hubs(id) ON DELETE CASCADE,
    FOREIGN KEY(project_id) REFERENCES projects(id) ON DELETE CASCADE
);

CREATE TRIGGER
    hub_related_projects_ai_1
AFTER INSERT ON
    hub_related_projects
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.hub_id,
        NEW.project_id,
        NEW.hash
    );

    INSERT INTO
        hub_related_changes(
            hub_id,
            change_id
        )
    SELECT
        NEW.hub_id,
        pu.change_id
    FROM
        project_changes pu
    WHERE
        pu.project_id = NEW.project_id
    ;

    /*
        Need to change project_related_changes_merkle for all of the
        project_related_changes that have occured before the project
        got added to the hub/repo.
    */

    INSERT INTO
        project_related_changes_merkle(
            project_id,
            hub_id,
            prefix,
            hash,
            num_changes
        )
    SELECT
        NEW.project_id,
        src.hub_id,
        SUBSTR(src.uuid,1,5),
        substr(agg_sha1_hex(src.uuid, src.uuid),1,8) AS hash,
        count(src.uuid) as num_changes
    FROM
        (
        SELECT
            hrp.hub_id,
            c.uuid
        FROM
            project_related_changes pru
        INNER JOIN
            hub_related_projects hrp
        ON
            hrp.hub_id = NEW.hub_id AND
            hrp.project_id = pru.real_project_id
        INNER JOIN
            changes c
        ON
            c.id = pru.change_id
        WHERE
            pru.project_id = NEW.project_id
        ) src
    GROUP BY
        NEW.project_id,
        src.hub_id,
        SUBSTR(src.uuid,1,5)
    ;

END;

CREATE TRIGGER
    hub_related_projects_ad_1
AFTER DELETE ON
    hub_related_projects
FOR EACH ROW
BEGIN
    SELECT debug(
        OLD.hub_id,
        OLD.project_id,
        OLD.hash
    );

    -- TODO also delete from hru_merkle?

    DELETE FROM
        hub_related_changes
    WHERE
        hub_id = OLD.hub_ID AND
        change_id IN (
            SELECT
                pu.change_id
            FROM
                project_changes pu
            WHERE
                pu.project_id = OLD.project_id
        )
    ;

    -- TODO where else do we need to delete entries in prum?
    DELETE FROM
        project_related_changes_merkle
    WHERE
        hub_id = OLD.hub_id AND
        project_id = OLD.project_id
    ;
END;
