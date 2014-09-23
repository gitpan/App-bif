CREATE TABLE project_topic_entities(
    project_id INTEGER NOT NULL,
    real_project_id INTEGER NOT NULL,
    entity_id INTEGER NOT NULL,
    UNIQUE(entity_id,project_id) ON CONFLICT IGNORE
    FOREIGN KEY(project_id) REFERENCES projects(id) ON DELETE CASCADE,
    FOREIGN KEY(real_project_id) REFERENCES projects(id) ON DELETE CASCADE,
    FOREIGN KEY(entity_id) REFERENCES entities(id) ON DELETE CASCADE
);

CREATE INDEX
    project_topic_entities_project_id
ON
    project_topic_entities(project_id)
;


CREATE TRIGGER
    project_topic_entities_ai_1
AFTER INSERT ON
    project_topic_entities
FOR EACH ROW
BEGIN
    SELECT debug(
        NEW.project_id,
        NEW.real_project_id,
        NEW.entity_id
    );


    INSERT INTO
        project_related_changes(
            project_id,
            real_project_id,
            change_id
        )
    SELECT
        NEW.project_id,
        NEW.real_project_id,
        eru.change_id
    FROM
        entity_related_changes eru
    WHERE
        eru.entity_id = NEW.entity_id
    ;
END;


CREATE TRIGGER
    project_topic_entities_ad_1
AFTER DELETE ON
    project_topic_entities
FOR EACH ROW
BEGIN
    SELECT debug(
        OLD.project_id,
        OLD.real_project_id,
        OLD.entity_id
    );

    DELETE FROM
        project_related_changes
    WHERE
        project_id = OLD.project_id AND
        real_project_id = OLD.real_project_id AND
        change_id IN (
            SELECT
                eru.change_id
            FROM
                entity_related_changes eru
            WHERE
                eru.entity_id = OLD.entity_id
        )
    ;
END;
