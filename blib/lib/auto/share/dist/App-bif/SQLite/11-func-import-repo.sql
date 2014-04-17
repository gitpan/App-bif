CREATE TABLE func_import_repo(
    location VARCHAR(40) NOT NULL
);

CREATE TRIGGER
    bi_func_import_repo_1
BEFORE INSERT ON
    func_import_repo
FOR EACH ROW
BEGIN

    SELECT debug(
        'TRIGGER bi_func_import_repo_1',
        NEW.location
    );

    -- DEFAULT VALUES doesn't work in a trigger?!?
    INSERT INTO
        func_new_repo
    VALUES(
        null
    );

    SELECT RAISE(IGNORE);
END;
