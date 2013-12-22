CREATE TABLE hubs (
    id integer NOT NULL PRIMARY KEY,
    alias varchar NOT NULL UNIQUE,
    location varchar NOT NULL UNIQUE,
    FOREIGN KEY (id) REFERENCES topics(id) ON DELETE CASCADE
);
