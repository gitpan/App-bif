CREATE TABLE project_related_updates(
    project_id INTEGER NOT NULL,
    real_project_id INTEGER NOT NULL,
    update_id INTEGER NOT NULL,
    merkled INTEGER NOT NULL DEFAULT 0,
    CONSTRAINT pru_merkled CHECK (
        merkled = 0 OR merkled = 1
    ),

    /*
        TODO: Remove the ON CONFLICT IGNORE clause below which is only
        needed because the queries that insert into this table are not
        yet as tight as they should be.
    */

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

/*
    This is needed for deletes triggered by updates_bd_1. The
    pru after-delete trigger needs to know the updates.uuid/prefix,
    however the necessary row from the updates table is not available
    at trigger time.

    TODO: The alternative to this big hammer is to store the update
    prefix in project_related_updates table as well.
*/

CREATE INDEX
    project_related_updates_update_id
ON
    project_related_updates(update_id)
;


CREATE TRIGGER
    project_related_updates_ai_1
AFTER INSERT ON
    project_related_updates
FOR EACH ROW
BEGIN

    SELECT debug(
        NEW.project_id,
        NEW.real_project_id
    );

    INSERT INTO
        project_topic_entities(
            project_id,
            real_project_id,
            entity_id
        )
    SELECT
        NEW.project_id,
        NEW.real_project_id,
        u.identity_id
    FROM
        updates u
    WHERE
        u.id = NEW.update_id
    ;

END;


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
        SUBSTR(src.uuid,1,5),
        substr(agg_sha1_hex(src.uuid, src.uuid),1,8) AS hash,
        count(src.uuid) as num_updates
    FROM
        (
        -- find updates with the same prefix as the current update
        -- that are related to the current project
        -- and add the hubs where the project is present
        SELECT
            hrp.hub_id,
            u2.uuid
        FROM
            updates u
        INNER JOIN
            updates u2
        ON
            u2.uuid LIKE SUBSTR(u.uuid, 1, 5) || '%'
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
        SUBSTR(src.uuid,1,5)
    ;

END;


/*
    This is the reverse of the _bu_1 trigger above - modify the _merkle
    table as if these rows were deleted.
*/
CREATE TRIGGER
    project_related_updates_bu_2
BEFORE UPDATE OF
    merkled
ON
    project_related_updates
FOR EACH ROW WHEN
    OLD.merkled = 1 AND NEW.merkled = 0
BEGIN
    SELECT debug(
        OLD.project_id,
        OLD.real_project_id,
        OLD.update_id,
        OLD.merkled
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
        p.id,
        p.hub_id,
        SUBSTR(u.uuid,1,5) AS prefix,
        SUBSTR(agg_sha1_hex(src.uuid, src.uuid),1,8) AS hash,
        COUNT(src.uuid) as num_updates
    FROM
        projects p
    INNER JOIN
        updates u
    ON
        u.id = OLD.update_id
    LEFT JOIN
        (
        -- find updates with the same prefix as the current update
        -- that are related to the current project
        -- and add the hubs where the project is present
        SELECT
            hrp.hub_id,
            u2.uuid
        FROM
            updates u
        INNER JOIN
            updates u2
        ON
            u2.uuid LIKE SUBSTR(u.uuid, 1, 5) || '%' AND
            u2.id != u.id
        INNER JOIN
            project_related_updates pru
        ON
            pru.update_id = u2.id AND
            pru.project_id = OLD.project_id
        INNER JOIN
            hub_related_projects hrp
        ON
            hrp.project_id = pru.real_project_id
        WHERE
            u.id = OLD.update_id
        ) src
    WHERE
        p.id = OLD.project_id AND
        p.hub_id IS NOT NULL
    GROUP BY
        p.id,
        p.hub_id,
        prefix
    ;

END;
