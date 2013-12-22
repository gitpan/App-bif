CREATE TABLE links (
    id integer NOT NULL,
    hub_id integer NOT NULL,
    topic_id integer NOT NULL,
    FOREIGN KEY(id) REFERENCES topics(id) ON DELETE CASCADE,
    FOREIGN KEY(hub_id) REFERENCES hubs(id) ON DELETE CASCADE,
    FOREIGN KEY(topic_id) REFERENCES topics(id) ON DELETE CASCADE,
    UNIQUE (hub_id, topic_id) ON CONFLICT IGNORE
);
