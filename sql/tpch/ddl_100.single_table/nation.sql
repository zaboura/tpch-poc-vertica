DROP TABLE IF EXISTS __SCHEMA__.nation;
CREATE TABLE __SCHEMA__.nation (
    n_nationkey  INT NOT NULL,
    n_name       VARCHAR(25) NOT NULL,
    n_regionkey  INT NOT NULL,
    n_comment    VARCHAR(152)
);