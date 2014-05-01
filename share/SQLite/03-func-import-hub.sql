CREATE TABLE func_import_hub(
    location VARCHAR(40) NOT NULL
);

CREATE TRIGGER
    bi_func_import_hub_1
BEFORE INSERT ON
    func_import_hub
FOR EACH ROW
BEGIN

    SELECT debug(
        'TRIGGER bi_func_import_hub_1',
        NEW.location
    );

    -- DEFAULT VALUES doesn't work in a trigger?!?
    INSERT INTO
        func_new_hub
    VALUES(
        null
    );

    SELECT RAISE(IGNORE);
END;
