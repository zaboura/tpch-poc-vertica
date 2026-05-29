DROP TABLE IF EXISTS __SCHEMA__.customer;
CREATE TABLE __SCHEMA__.customer (
    c_custkey     INT NOT NULL,
    c_name        VARCHAR(25) NOT NULL,
    c_address     VARCHAR(40) NOT NULL,
    c_nationkey   INT NOT NULL,
    c_phone       VARCHAR(15) NOT NULL,
    c_acctbal     DECIMAL(15,2) NOT NULL,
    c_mktsegment  VARCHAR(10) NOT NULL,
    c_comment     VARCHAR(117) NOT NULL
);