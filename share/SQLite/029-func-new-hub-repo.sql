CREATE TABLE func_new_hub_repo(
    update_id INTEGER NOT NULL,
    id INTEGER NOT NULL DEFAULT (nextval('topics')),
    hub_id INTEGER NOT NULL,
    location VARCHAR NOT NULL
);

CREATE TRIGGER
    func_new_hub_repo_bi_1
BEFORE INSERT ON
    func_new_hub_repo
FOR EACH ROW
BEGIN

    SELECT debug(
        'TRIGGER func_new_hub_repo_bi_1',
        NEW.id,
        NEW.update_id,
        NEW.hub_id,
        NEW.location
    );


    INSERT INTO
        hub_repos(
            id,
            hub_id,
            location
        )
    VALUES(
        NEW.id,
        NEW.hub_id,
        NEW.location
    );

    INSERT INTO
        hub_repo_deltas(
            update_id,
            hub_id,
            hub_repo_id,
            new,
            location
        )
    VALUES(
        NEW.update_id,
        NEW.hub_id,
        NEW.id,
        1,
        NEW.location
    );

    SELECT RAISE(IGNORE);
END;
