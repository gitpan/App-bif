CREATE TABLE repo_related_updates(
    repo_id INTEGER NOT NULL,
    update_id INTEGER NOT NULL,
    merkled INTEGER NOT NULL DEFAULT 0,
    UNIQUE(repo_id,update_id) ON CONFLICT IGNORE,
    CHECK (merkled = 0 OR merkled = 1),
    FOREIGN KEY(repo_id) REFERENCES repos(id) ON DELETE CASCADE,
    FOREIGN KEY(update_id) REFERENCES updates(id) ON DELETE CASCADE
);

/*
    Only need to do this for update_id as the UNIQUE condition above
    should work as a covering index for "WHERE repo_id =" expressions.
*/
CREATE INDEX
    repo_related_updates_update_id
ON
    repo_related_updates(update_id)
;
