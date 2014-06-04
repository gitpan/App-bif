CREATE TABLE project_related_updates(
    project_id INTEGER NOT NULL,
    real_project_id INTEGER NOT NULL,
    update_id INTEGER NOT NULL,
    merkled INTEGER NOT NULL DEFAULT 0,
    CONSTRAINT pru_merkled CHECK (
        merkled = 0 OR merkled = 1
    ),
    UNIQUE(update_id,project_id) ON CONFLICT IGNORE
    FOREIGN KEY(project_id) REFERENCES projects(id) ON DELETE CASCADE,
    FOREIGN KEY(real_project_id) REFERENCES projects(id) ON DELETE CASCADE,
    FOREIGN KEY(update_id) REFERENCES updates(id) ON DELETE CASCADE
);

/*
    TODO This needs to be measured with various combinations of
    project_id, hub_id and update_id. I suspect update_id first is
    best.
CREATE INDEX
    project_related_updates_project_id_hub_id
ON
    project_related_updates(project_id,hub_id)
;
*/

CREATE TRIGGER
    project_related_updates_bu_1
BEFORE UPDATE OF
    merkled
ON
    project_related_updates
FOR EACH ROW WHEN
    NEW.merkled = 1
BEGIN
    SELECT debug(
        NEW.project_id,
        NEW.real_project_id,
        NEW.update_id,
        NEW.merkled
    );

    INSERT INTO
        project_related_updates_merkle(
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
            pru.update_id = u2.id AND
            pru.project_id = NEW.project_id
        INNER JOIN
            hub_related_projects hrp
        ON
            hrp.project_id = pru.real_project_id
        WHERE
            u.id = NEW.update_id
        ) src
    GROUP BY
        NEW.project_id,
        src.hub_id,
        src.prefix
    ;

END;
