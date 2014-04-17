CREATE TABLE default_status (
    project_type VARCHAR(40) NOT NULL DEFAULT 'default',
    kind VARCHAR(40) NOT NULL,
    status VARCHAR(40) NOT NULL,
    rank INTEGER NOT NULL,
    def INTEGER,
    PRIMARY KEY (kind,status),
    CHECK (def = 1 OR def IS NULL)
);

CREATE TRIGGER ai_default_status
    AFTER INSERT ON default_status
FOR EACH ROW WHEN NEW.def = 1
BEGIN
    UPDATE
        default_status
    SET
        def = NULL
    WHERE
        kind = NEW.kind AND status != NEW.status AND def = 1
    ;
END;

CREATE TRIGGER au_default_status
    AFTER UPDATE ON default_status
FOR EACH ROW WHEN NEW.def = 1
BEGIN
    UPDATE
        default_status
    SET
        def = NULL
    WHERE
        kind = NEW.kind AND status != NEW.status AND def = 1
    ;
END;


INSERT INTO default_status(kind,status,rank)
    VALUES('project','define',10);

INSERT INTO default_status(kind,status,rank)
    VALUES('project','plan',20);

INSERT INTO default_status(kind,status,rank,def)
    VALUES('project','run',30, 1);

INSERT INTO default_status(kind,status,rank)
    VALUES('project','eval',40);

INSERT INTO default_status(kind,status,rank)
    VALUES('project','closed',50);


INSERT INTO default_status(kind,status,rank,def)
    VALUES('task','open',10, 1);

INSERT INTO default_status(kind,status,rank)
    VALUES('task','stalled',20);

INSERT INTO default_status(kind,status,rank)
    VALUES('task','closed',30);

INSERT INTO default_status(kind,status,rank)
    VALUES('task','nostatus',40);


INSERT INTO default_status(kind,status,rank,def)
    VALUES('issue','open',10, 1);

INSERT INTO default_status(kind,status,rank)
    VALUES('issue','stalled',20);

INSERT INTO default_status(kind,status,rank)
    VALUES('issue','closed',30);

INSERT INTO default_status(kind,status,rank)
    VALUES('issue','nostatus',40);

