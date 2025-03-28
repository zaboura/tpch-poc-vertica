DROP SCHEMA IF EXISTS tpch CASCADE;
CREATE SCHEMA IF NOT EXISTS tpch;

DROP TABLE IF EXISTS tpch.customer;
CREATE TABLE tpch.customer (
    c_custkey     INT NOT NULL,
    c_name        VARCHAR(25) NOT NULL,
    c_address     VARCHAR(40) NOT NULL,
    c_nationkey   INT NOT NULL,
    c_phone       VARCHAR(15) NOT NULL,
    c_acctbal     DECIMAL(15,2) NOT NULL,
    c_mktsegment  VARCHAR(10) NOT NULL,
    c_comment     VARCHAR(117) NOT NULL
);

DROP TABLE IF EXISTS tpch.lineitem;
CREATE TABLE tpch.lineitem (
    l_linenumber  INT NOT NULL,
    l_partkey     INT NOT NULL,
    l_suppkey     INT NOT NULL,
    l_orderkey    INT NOT NULL,
    l_quantity    DECIMAL(15,2) NOT NULL,
    l_extendedprice DECIMAL(15,2) NOT NULL,
    l_discount    DECIMAL(15,2) NOT NULL,
    l_tax         DECIMAL(15,2) NOT NULL,
    l_returnflag  VARCHAR(1) NOT NULL,
    l_linestatus  VARCHAR(1) NOT NULL,
    l_shipdate    DATE NOT NULL,
    l_commitdate  DATE NOT NULL,
    l_receiptdate DATE NOT NULL,
    l_shipinstruct VARCHAR(25) NOT NULL,
    l_shipmode     VARCHAR(10) NOT NULL,
    l_comment      VARCHAR(44) NOT NULL
);

DROP TABLE IF EXISTS tpch.nation;
CREATE TABLE tpch.nation (
    n_nationkey  INT NOT NULL,
    n_name       VARCHAR(25) NOT NULL,
    n_regionkey  INT NOT NULL,
    n_comment    VARCHAR(152)
);

DROP TABLE IF EXISTS tpch.orders;
CREATE TABLE tpch.orders (
    o_orderkey      INT NOT NULL,
    o_custkey       INT NOT NULL,
    o_orderstatus   VARCHAR(1) NOT NULL,
    o_totalprice    DECIMAL(15,2) NOT NULL,
    o_orderdate     DATE NOT NULL,
    o_orderpriority VARCHAR(15) NOT NULL,
    o_clerk         VARCHAR(15) NOT NULL,
    o_shippriority  INT NOT NULL,
    o_comment       VARCHAR(79) NOT NULL
);

DROP TABLE IF EXISTS tpch.part;
CREATE TABLE tpch.part (
    p_partkey     INT NOT NULL,
    p_name        VARCHAR(55) NOT NULL,
    p_mfgr        VARCHAR(25) NOT NULL,
    p_brand       VARCHAR(10) NOT NULL,
    p_type        VARCHAR(25) NOT NULL,
    p_size        INT NOT NULL,
    p_container   VARCHAR(10) NOT NULL,
    p_retailprice DECIMAL(15,2) NOT NULL,
    p_comment     VARCHAR(23) NOT NULL
);

DROP TABLE IF EXISTS tpch.partsupp;
CREATE TABLE tpch.partsupp (
    ps_partkey     INT NOT NULL,
    ps_suppkey     INT NOT NULL,
    ps_availqty    INT NOT NULL,
    ps_supplycost  DECIMAL(15,2) NOT NULL,
    ps_comment     VARCHAR(199) NOT NULL
);

DROP TABLE IF EXISTS tpch.region;
CREATE TABLE tpch.region (
    r_regionkey INT NOT NULL,
    r_name      VARCHAR(25) NOT NULL,
    r_comment   VARCHAR(152)
);

DROP TABLE IF EXISTS tpch.supplier;
CREATE TABLE tpch.supplier (
    s_suppkey   INT NOT NULL,
    s_name      VARCHAR(25) NOT NULL,
    s_address   VARCHAR(40) NOT NULL,
    s_nationkey INT NOT NULL,
    s_phone     VARCHAR(15) NOT NULL,
    s_acctbal   DECIMAL(15,2) NOT NULL,
    s_comment   VARCHAR(101) NOT NULL
);

DROP VIEW IF EXISTS tpch.revenue0;
CREATE VIEW tpch.revenue0 (supplier_no, total_revenue) AS
SELECT
    l_suppkey,
    SUM(l_extendedprice * (1 - l_discount))
FROM
    tpch.lineitem
WHERE
    l_shipdate >= DATE '1996-01-01'
    AND l_shipdate < DATE '1996-01-01' + INTERVAL '3 MONTH'
GROUP BY
    l_suppkey;
