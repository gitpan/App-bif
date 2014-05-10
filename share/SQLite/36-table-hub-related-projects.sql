CREATE TABLE hub_related_projects(
    hub_id INTEGER NOT NULL,
    project_id INTEGER NOT NULL,
    update_id INTEGER NOT NULL,
    hash VARCHAR(8) NOT NULL DEFAULT '',
    UNIQUE(hub_id,project_id),
    FOREIGN KEY(hub_id) REFERENCES hubs(id) ON DELETE CASCADE,
    FOREIGN KEY(project_id) REFERENCES projects(id) ON DELETE CASCADE,
    FOREIGN KEY(update_id) REFERENCES updates(id) ON DELETE CASCADE
);

CREATE TRIGGER
    ai_hub_related_projects
AFTER INSERT ON
    hub_related_projects
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.hub_id,
        NEW.project_id,
        NEW.update_id,
        NEW.hash
    );

    INSERT INTO
        hub_related_updates(
            hub_id,
            update_id
        )
    SELECT
        NEW.hub_id,
        pmu.update_id
    FROM
        project_meta_updates pmu
    WHERE
        pmu.project_id = NEW.project_id
    ;

    /*
        Need to update projects_merkle for all of the
        project_related_updates that have occured before the project
        got added to the hub/repo.
    */

    INSERT INTO
        projects_merkle(
            project_id,
            hub_id,
            prefix,
            hash,
            num_updates
        )
    SELECT
        NEW.project_id,
        src.hub_id,
        src.prefix,
        substr(agg_sha1_hex(src.uuid, src.uuid),1,8) AS hash,
        count(src.uuid) as num_updates
    FROM
        (
        SELECT
            hrp.hub_id,
            u.prefix,
            u.uuid
        FROM
            project_related_updates pru
        INNER JOIN
            hub_related_projects hrp
        ON
            hrp.hub_id = NEW.hub_id AND
            hrp.project_id = pru.real_project_id
        INNER JOIN
            updates u
        ON
            u.id = pru.update_id
        WHERE
            pru.project_id = NEW.project_id
        ) src
    GROUP BY
        NEW.project_id,
        src.hub_id,
        src.prefix
    ;

END;
