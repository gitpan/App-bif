CREATE TABLE default_status (
    project_type VARCHAR(40) NOT NULL DEFAULT 'default',
    kind VARCHAR(40) NOT NULL,
    status VARCHAR(40) NOT NULL,
    rank INTEGER NOT NULL,
    def INTEGER,
    PRIMARY KEY (kind,status),
    CHECK (def = 1 OR def IS NULL)
);

CREATE TRIGGER
    default_status_bi_1
BEFORE INSERT ON
    default_status
FOR EACH ROW WHEN
    NEW.def = 1
BEGIN
    UPDATE
        default_status
    SET
        def = NULL
    WHERE
        kind = NEW.kind AND def = 1
    ;
END;

CREATE TRIGGER
    default_status_bu_1
BEFORE UPDATE OF
    def
ON
    default_status
FOR EACH ROW WHEN
    OLD.def IS NULL AND NEW.def = 1
BEGIN
    UPDATE
        default_status
    SET
        def = NULL
    WHERE
        kind = NEW.kind AND def = 1
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
    VALUES('task','done',30);

INSERT INTO default_status(kind,status,rank)
    VALUES('task','-',40);


INSERT INTO default_status(kind,status,rank,def)
    VALUES('issue','open',10, 1);

INSERT INTO default_status(kind,status,rank)
    VALUES('issue','stalled',20);

INSERT INTO default_status(kind,status,rank)
    VALUES('issue','closed',30);

INSERT INTO default_status(kind,status,rank)
    VALUES('issue','-',40);

