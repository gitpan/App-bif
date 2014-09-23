CREATE TABLE project_related_changes(
    project_id INTEGER NOT NULL,
    real_project_id INTEGER NOT NULL,
    change_id INTEGER NOT NULL,
    merkled INTEGER NOT NULL DEFAULT 0,
    CONSTRAINT pru_merkled CHECK (
        merkled = 0 OR merkled = 1
    ),

    /*
        TODO: Remove the ON CONFLICT IGNORE clause below which is only
        needed because the queries that insert into this table are not
        yet as tight as they should be.
    */

    UNIQUE(change_id,project_id) ON CONFLICT IGNORE
    FOREIGN KEY(project_id) REFERENCES projects(id) ON DELETE CASCADE,
    FOREIGN KEY(real_project_id) REFERENCES projects(id) ON DELETE CASCADE,
    FOREIGN KEY(change_id) REFERENCES changes(id) ON DELETE CASCADE
);

/*
    TODO This needs to be measured with various combinations of
    project_id, hub_id and change_id. I suspect change_id first is
    best.

    CREATE INDEX
        project_related_changes_project_id_hub_id
    ON
        project_related_changes(project_id,hub_id)
    ;

*/

/*
    This is needed for deletes triggered by changes_bd_1. The
    pru after-delete trigger needs to know the changes.uuid/prefix,
    however the necessary row from the changes table is not available
    at trigger time.

    TODO: The alternative to this big hammer is to store the change
    prefix in project_related_changes table as well.
*/

CREATE INDEX
    project_related_changes_change_id
ON
    project_related_changes(change_id)
;


CREATE TRIGGER
    project_related_changes_ai_1
AFTER INSERT ON
    project_related_changes
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
        c.identity_id
    FROM
        changes c
    WHERE
        c.id = NEW.change_id
    ;

END;


CREATE TRIGGER
    project_related_changes_bu_1
BEFORE UPDATE OF
    merkled
ON
    project_related_changes
FOR EACH ROW WHEN
    NEW.merkled = 1
BEGIN
    SELECT debug(
        NEW.project_id,
        NEW.real_project_id,
        NEW.change_id,
        NEW.merkled
    );

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
        -- find changes with the same prefix as the current change
        -- that are related to the current project
        -- and add the hubs where the project is present
        SELECT
            hrp.hub_id,
            c2.uuid
        FROM
            changes c
        INNER JOIN
            changes c2
        ON
            c2.uuid LIKE SUBSTR(c.uuid, 1, 5) || '%'
        INNER JOIN
            project_related_changes pru
        ON
            pru.change_id = c2.id AND
            pru.project_id = NEW.project_id
        INNER JOIN
            hub_related_projects hrp
        ON
            hrp.project_id = pru.real_project_id
        WHERE
            c.id = NEW.change_id
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
    project_related_changes_bu_2
BEFORE UPDATE OF
    merkled
ON
    project_related_changes
FOR EACH ROW WHEN
    OLD.merkled = 1 AND NEW.merkled = 0
BEGIN
    SELECT debug(
        OLD.project_id,
        OLD.real_project_id,
        OLD.change_id,
        OLD.merkled
    );


    INSERT INTO
        project_related_changes_merkle(
            project_id,
            hub_id,
            prefix,
            hash,
            num_changes
        )
    SELECT
        p.id,
        p.hub_id,
        SUBSTR(c.uuid,1,5) AS prefix,
        SUBSTR(agg_sha1_hex(src.uuid, src.uuid),1,8) AS hash,
        COUNT(src.uuid) as num_changes
    FROM
        projects p
    INNER JOIN
        changes c
    ON
        c.id = OLD.change_id
    LEFT JOIN
        (
        -- find changes with the same prefix as the current change
        -- that are related to the current project
        -- and add the hubs where the project is present
        SELECT
            hrp.hub_id,
            c2.uuid
        FROM
            changes c
        INNER JOIN
            changes c2
        ON
            c2.uuid LIKE SUBSTR(c.uuid, 1, 5) || '%' AND
            c2.id != c.id
        INNER JOIN
            project_related_changes pru
        ON
            pru.change_id = c2.id AND
            pru.project_id = OLD.project_id
        INNER JOIN
            hub_related_projects hrp
        ON
            hrp.project_id = pru.real_project_id
        WHERE
            c.id = OLD.change_id
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
