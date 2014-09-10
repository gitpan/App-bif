CREATE TABLE issues (
    id INTEGER PRIMARY KEY NOT NULL,
    title VARCHAR(1024) NOT NULL DEFAULT '',
    FOREIGN KEY(id) REFERENCES topics(id) ON DELETE CASCADE
);


CREATE TRIGGER
    issues_ad_1
AFTER DELETE ON
    issues
FOR EACH ROW
BEGIN
    SELECT debug(
        OLD.id,
        OLD.title
    );

    DELETE FROM
        topics
    WHERE
        id = OLD.id
    ;

END;
