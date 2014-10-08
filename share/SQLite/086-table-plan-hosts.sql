CREATE TABLE plan_hosts(
    --id INT NOT NULL PRIMARY KEY,
    plan_id INTEGER NOT NULL,
    host_id INTEGER NOT NULL,
    UNIQUE(plan_id,host_id),
    FOREIGN KEY(plan_id) REFERENCES plans(id),
    FOREIGN KEY(host_id) REFERENCES hosts(id)
);
