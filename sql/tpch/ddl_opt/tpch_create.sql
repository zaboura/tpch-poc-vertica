DROP SCHEMA IF EXISTS __SCHEMA__ CASCADE;
CREATE SCHEMA IF NOT EXISTS __SCHEMA__;

----------------------------------------------------------------------------
---------------RUN DBD---------------------------------------------------------
----------------------------------------------------------------------------


SELECT DESIGNER_DROP_DESIGN('MC_TPCH');
SELECT DESIGNER_CREATE_DESIGN('MC_TPCH');
SELECT DESIGNER_SET_DESIGN_TYPE('MC_TPCH', 'COMPREHENSIVE');
SELECT DESIGNER_SET_OPTIMIZATION_OBJECTIVE('MC_TPCH', 'QUERY');
SELECT DESIGNER_ADD_DESIGN_TABLES('MC_TPCH', '__SCHEMA__.*', true);
SELECT DESIGNER_RUN_POPULATE_DESIGN_AND_DEPLOY(
    'MC_TPCH',                                      -- Design name
    '/home/dbadmin/tpch-poc-vertica/pdm.sql',      -- Optimized DDL
    '/home/dbadmin/tpch-poc-vertica/deploy.sql',   -- Deployment script
    true,                                           -- Analyze stats before designing PDM
    true,                                           -- Deploy
    false,                                          -- Drop workspace after deploying
    false                                           -- Continue after errors
);
SELECT DESIGNER_WAIT_FOR_DESIGN('MC_TPCH');

--------------------------------------------------------------------------
------NATION TABLE-------------------------------------------------------
--------------------------------------------------------------------------

CREATE TABLE __SCHEMA__.nation (
    n_nationkey  INT         NOT NULL,
    n_name       VARCHAR(25) NOT NULL,
    n_regionkey  INT         NOT NULL,
    n_comment    VARCHAR(152)
) UNSEGMENTED ALL NODES;

CREATE PROJECTION __SCHEMA__.nation_super
(
 n_nationkey ENCODING COMMONDELTA_COMP,
 n_name ENCODING ZSTD_FAST_COMP,
 n_regionkey,
 n_comment ENCODING ZSTD_FAST_COMP
)
AS
 SELECT nation.n_nationkey,
        nation.n_name,
        nation.n_regionkey,
        nation.n_comment
 FROM __SCHEMA__.nation
 ORDER BY nation.n_nationkey,
          nation.n_name,
          nation.n_regionkey,
          nation.n_comment
UNSEGMENTED ALL NODES;


--Query 08
CREATE PROJECTION __SCHEMA__.nation_q08 
(
 n_nationkey ENCODING COMMONDELTA_COMP,
 n_name ENCODING ZSTD_FAST_COMP,
 n_regionkey
)
AS
 SELECT nation.n_nationkey,
        nation.n_name,
        nation.n_regionkey
 FROM __SCHEMA__.nation
 ORDER BY nation.n_nationkey
UNSEGMENTED ALL NODES;


SELECT MARK_DESIGN_KSAFE(1);


SELECT MARK_DESIGN_KSAFE(1);


select refresh('__SCHEMA__.nation');
--------------------------------------------------------------------------
------REGION TABLE------------------------------------------------------
--------------------------------------------------------------------------
CREATE TABLE __SCHEMA__.region (
    r_regionkey INT         NOT NULL,
    r_name      VARCHAR(25) NOT NULL,
    r_comment   VARCHAR(152)
) UNSEGMENTED ALL NODES;


CREATE PROJECTION __SCHEMA__.region_proj_unseg_name_sort
(
 r_regionkey ENCODING AUTO, 
 r_name ENCODING AUTO
)
AS
 SELECT r_regionkey, 
        r_name
 FROM __SCHEMA__.region 
 ORDER BY r_name,
          r_regionkey
UNSEGMENTED ALL NODES;


SELECT MARK_DESIGN_KSAFE(1);


select refresh('__SCHEMA__.region');


----------------------------------------------------------------------------
------CUSTOMER TABLE------------------------------------------------------
----------------------------------------------------------------------------
CREATE TABLE __SCHEMA__.customer (
    c_custkey     INT         NOT NULL,
    c_name        VARCHAR(25) NOT NULL,
    c_address     VARCHAR(40) NOT NULL,
    c_nationkey   INT         NOT NULL,
    c_phone       VARCHAR(15) NOT NULL,
    c_acctbal     DECIMAL(15,2) NOT NULL,
    c_mktsegment  VARCHAR(10) NOT NULL,
    c_comment     VARCHAR(117) NOT NULL
) UNSEGMENTED ALL NODES;

CREATE PROJECTION customer_seg
(
 c_custkey ENCODING COMMONDELTA_COMP, 
 c_mktsegment ENCODING RLE
)
AS
 SELECT c_custkey, 
        c_mktsegment
 FROM __SCHEMA__.customer 
 ORDER BY c_mktsegment,
          c_custkey
SEGMENTED BY MODULARHASH (c_custkey) ALL NODES;


--Query 05
CREATE PROJECTION __SCHEMA__.customer_rep
(
 c_custkey ENCODING COMMONDELTA_COMP,
 c_nationkey ENCODING BLOCKDICT_COMP
)
AS
 SELECT customer.c_custkey,
        customer.c_nationkey
 FROM __SCHEMA__.customer
 ORDER BY customer.c_custkey
UNSEGMENTED ALL NODES;



--Query 07
CREATE PROJECTION __SCHEMA__.customer_q07 
(
 c_custkey ENCODING COMMONDELTA_COMP,
 c_nationkey ENCODING BLOCKDICT_COMP
)
AS
 SELECT customer.c_custkey,
        customer.c_nationkey
 FROM __SCHEMA__.customer
 ORDER BY customer.c_custkey
SEGMENTED BY hash(customer.c_custkey) ALL NODES OFFSET 0;



CREATE PROJECTION __SCHEMA__.customer_q10 
(
 c_custkey ENCODING DELTAVAL,
 c_name ENCODING ZSTD_FAST_COMP,
 c_address ENCODING ZSTD_FAST_COMP,
 c_nationkey ENCODING RLE,
 c_phone ENCODING ZSTD_FAST_COMP,
 c_acctbal ENCODING DELTAVAL,
 c_comment ENCODING ZSTD_FAST_COMP
)
AS
 SELECT customer.c_custkey,
        customer.c_name,
        customer.c_address,
        customer.c_nationkey,
        customer.c_phone,
        customer.c_acctbal,
        customer.c_comment
 FROM __SCHEMA__.customer
 ORDER BY customer.c_nationkey,
          customer.c_address
SEGMENTED BY hash(customer.c_custkey) ALL NODES OFFSET 0;



-- Query 13
CREATE PROJECTION __SCHEMA__.customer_DBD_1_seg_MC_TPCH_INC1_v1_b0 /*+basename(customer_DBD_1_seg_MC_TPCH_INC1_v1),createtype(D)*/ 
(
 c_custkey ENCODING COMMONDELTA_COMP
)
AS
 SELECT customer.c_custkey
 FROM __SCHEMA__.customer
 ORDER BY customer.c_custkey
SEGMENTED BY hash(customer.c_custkey) ALL NODES OFFSET 0;

-- Query 18



CREATE PROJECTION __SCHEMA__.customer_DBD_1_seg_MC_TPCH_COMP_b0 /*+basename(customer_DBD_1_seg_MC_TPCH_COMP),createtype(D)*/ 
(
 c_custkey ENCODING DELTAVAL,
 c_name ENCODING ZSTD_FAST_COMP,
 c_address ENCODING ZSTD_FAST_COMP,
 c_nationkey ENCODING RLE,
 c_phone ENCODING ZSTD_FAST_COMP,
 c_acctbal ENCODING DELTAVAL,
 c_mktsegment ENCODING RLE,
 c_comment ENCODING ZSTD_FAST_COMP
)
AS
 SELECT customer.c_custkey,
        customer.c_name,
        customer.c_address,
        customer.c_nationkey,
        customer.c_phone,
        customer.c_acctbal,
        customer.c_mktsegment,
        customer.c_comment
 FROM __SCHEMA__.customer
 ORDER BY customer.c_mktsegment,
          customer.c_nationkey,
          customer.c_address
SEGMENTED BY hash(customer.c_address) ALL NODES OFFSET 0;

-- Query 22


CREATE PROJECTION __SCHEMA__.customer_DBD_1_seg_MC_TPCH_INC1
(
 c_custkey ENCODING DELTAVAL,
 c_phone ENCODING ZSTD_FAST_COMP,
 c_acctbal ENCODING RLE
)
AS
 SELECT customer.c_custkey,
        customer.c_phone,
        customer.c_acctbal
 FROM __SCHEMA__.customer
 ORDER BY customer.c_acctbal,
          customer.c_custkey
SEGMENTED BY hash(customer.c_custkey) ALL NODES OFFSET 0;


SELECT MARK_DESIGN_KSAFE(1);


SELECT MARK_DESIGN_KSAFE(1);



select refresh('__SCHEMA__.customer');

----------------------------------------------------------------------------
------SUPPLIER TABLE------------------------------------------------------
----------------------------------------------------------------------------

CREATE TABLE __SCHEMA__.supplier (
    s_suppkey   INT         NOT NULL,
    s_name      VARCHAR(25) NOT NULL,
    s_address   VARCHAR(40) NOT NULL,
    s_nationkey INT         NOT NULL,
    s_phone     VARCHAR(15) NOT NULL,
    s_acctbal   DECIMAL(15,2) NOT NULL,
    s_comment   VARCHAR(101) NOT NULL
) UNSEGMENTED ALL NODES;

CREATE PROJECTION __SCHEMA__.supplier_rep
AS SELECT *
   FROM __SCHEMA__.supplier
   ORDER BY s_suppkey
UNSEGMENTED ALL NODES;   

--Query 05
CREATE PROJECTION __SCHEMA__.supplier_DBD_1_rep_MC_TPCH_INC1
(
 s_suppkey ENCODING COMMONDELTA_COMP,
 s_nationkey ENCODING RLE
)
AS
 SELECT supplier.s_suppkey,
        supplier.s_nationkey
 FROM __SCHEMA__.supplier
 ORDER BY supplier.s_nationkey,
          supplier.s_suppkey
UNSEGMENTED ALL NODES;


--Query 08
CREATE PROJECTION __SCHEMA__.supplier_DBD_3_seg_MC_TPCH_INC1_b0 /*+basename(supplier_DBD_3_seg_MC_TPCH_INC1),createtype(D)*/ 
(
 s_suppkey ENCODING COMMONDELTA_COMP,
 s_nationkey ENCODING RLE
)
AS
 SELECT supplier.s_suppkey,
        supplier.s_nationkey
 FROM __SCHEMA__.supplier
 ORDER BY supplier.s_nationkey,
          supplier.s_suppkey
SEGMENTED BY hash(supplier.s_suppkey) ALL NODES OFFSET 0;


SELECT MARK_DESIGN_KSAFE(1);


select refresh('__SCHEMA__.supplier');



----------------------------------------------------------------------------
------PART TABLE----------------------------------------------------------
----------------------------------------------------------------------------    

CREATE TABLE __SCHEMA__.part (
    p_partkey     INT         NOT NULL,
    p_name        VARCHAR(55) NOT NULL,
    p_mfgr        VARCHAR(25) NOT NULL,
    p_brand       VARCHAR(10) NOT NULL,
    p_type        VARCHAR(25) NOT NULL,
    p_size        INT         NOT NULL,
    p_container   VARCHAR(10) NOT NULL,
    p_retailprice DECIMAL(15,2) NOT NULL,
    p_comment     VARCHAR(23) NOT NULL
) 
UNSEGMENTED ALL NODES;

CREATE PROJECTION __SCHEMA__.part_by_size_type_pk
AS SELECT p_partkey, p_size, p_type, p_mfgr, p_brand, p_container
   FROM __SCHEMA__.part
   ORDER BY p_size, p_partkey         
SEGMENTED BY HASH(p_partkey) ALL NODES;       



--Query 08
CREATE PROJECTION __SCHEMA__.part_DBD_3_seg_MC_TPCH_INC1_b0 /*+basename(part_DBD_3_seg_MC_TPCH_INC1),createtype(D)*/ 
(
 p_partkey ENCODING DELTARANGE_COMP,
 p_type ENCODING RLE
)
AS
 SELECT part.p_partkey,
        part.p_type
 FROM __SCHEMA__.part
 ORDER BY part.p_type,
          part.p_partkey
SEGMENTED BY hash(part.p_partkey) ALL NODES OFFSET 0;

--Query 14
CREATE PROJECTION __SCHEMA__.part_DBD_3_seg_MC_TPCH_INC1_b0 /*+basename(part_DBD_3_seg_MC_TPCH_INC1),createtype(D)*/ 
(
 p_partkey ENCODING DELTARANGE_COMP,
 p_type ENCODING RLE
)
AS
 SELECT part.p_partkey,
        part.p_type
 FROM __SCHEMA__.part
 ORDER BY part.p_type,
          part.p_partkey
SEGMENTED BY hash(part.p_partkey) ALL NODES OFFSET 0;


--Query 17
CREATE PROJECTION __SCHEMA__.part_DBD_2_seg_MC_TPCH_INC1_b0 /*+basename(part_DBD_2_seg_MC_TPCH_INC1),createtype(D)*/ 
(
 p_partkey ENCODING DELTARANGE_COMP,
 p_brand ENCODING RLE,
 p_container ENCODING RLE
)
AS
 SELECT part.p_partkey,
        part.p_brand,
        part.p_container
 FROM __SCHEMA__.part
 ORDER BY part.p_container,
          part.p_brand,
          part.p_partkey
SEGMENTED BY hash(part.p_partkey) ALL NODES OFFSET 0;

SELECT MARK_DESIGN_KSAFE(1);


select refresh('__SCHEMA__.part');




----------------------------------------------------------------------------
------LINEITEM TABLE------------------------------------------------------
----------------------------------------------------------------------------

CREATE TABLE __SCHEMA__.lineitem (
    l_linenumber    INT         NOT NULL,
    l_partkey       INT         NOT NULL,
    l_suppkey       INT         NOT NULL,
    l_orderkey      INT         NOT NULL,
    l_quantity      DECIMAL(15,2) NOT NULL,
    l_extendedprice DECIMAL(15,2) NOT NULL,
    l_discount      DECIMAL(15,2) NOT NULL,
    l_tax           DECIMAL(15,2) NOT NULL,
    l_returnflag    VARCHAR(1)  NOT NULL,
    l_linestatus    VARCHAR(1)  NOT NULL,
    l_shipdate      DATE        NOT NULL,
    l_commitdate    DATE        NOT NULL,
    l_receiptdate   DATE        NOT NULL,
    l_shipinstruct  VARCHAR(25) NOT NULL,
    l_shipmode      VARCHAR(10) NOT NULL,
    l_comment       VARCHAR(44) NOT NULL
)
;


--Query 01
CREATE PROJECTION __SCHEMA__.lineitem_DBD_2_seg_BENCH_COMPR_optim2_b1
(
l_linenumber ENCODING DELTARANGE_COMP,
l_quantity ENCODING RLE,
l_extendedprice ENCODING DELTARANGE_COMP,
l_discount ENCODING RLE,
l_tax ENCODING RLE,
l_returnflag ENCODING RLE,
l_linestatus ENCODING RLE,
l_shipdate ENCODING DELTAVAL
)
AS
SELECT  lineitem.l_linenumber,
        lineitem.l_quantity,
        lineitem.l_extendedprice,
        lineitem.l_discount,
        lineitem.l_tax,
        lineitem.l_returnflag,
        lineitem.l_linestatus,
        lineitem.l_shipdate
FROM __SCHEMA__.lineitem
ORDER BY lineitem.l_linestatus,
          lineitem.l_returnflag,
          lineitem.l_tax,
          lineitem.l_discount,
          lineitem.l_quantity,
          lineitem.l_linenumber
SEGMENTED BY hash(lineitem.l_linenumber) ALL NODES;
 
 
SELECT MARK_DESIGN_KSAFE(1);



CREATE PROJECTION lineitem_proj_sort_status_seg_linenumber

(
 l_linenumber ENCODING DELTAVAL,
 l_quantity ENCODING RLE, 
 l_extendedprice ENCODING DELTAVAL, 
 l_discount ENCODING RLE, 
 l_tax ENCODING RLE, 
 l_returnflag ENCODING RLE, 
 l_linestatus ENCODING RLE, 
 l_shipdate ENCODING RLE
)
AS
 SELECT l_linenumber,
 		l_quantity, 
        l_extendedprice, 
        l_discount, 
        l_tax, 
        l_returnflag, 
        l_linestatus, 
        l_shipdate
 FROM __SCHEMA__.lineitem 
 ORDER BY l_returnflag,
          l_linestatus,
          l_shipdate,
          l_tax,
          l_discount,
          l_quantity,
          l_extendedprice
SEGMENTED BY hash(lineitem.l_linenumber) ALL NODES KSAFE 1;


--Query 04
CREATE PROJECTION __SCHEMA__.lineitem_DBD_1_seg_MC_TPCH_INC1
(
 l_orderkey ENCODING RLE,
 l_shipdate ENCODING COMMONDELTA_COMP,
 l_commitdate ENCODING RLE,
 l_receiptdate ENCODING RLE
)
AS
 SELECT lineitem.l_orderkey,
        lineitem.l_shipdate,
        lineitem.l_commitdate,
        lineitem.l_receiptdate
 FROM __SCHEMA__.lineitem
 ORDER BY lineitem.l_commitdate,
          lineitem.l_receiptdate,
          lineitem.l_orderkey,
          lineitem.l_shipdate
SEGMENTED BY hash(lineitem.l_receiptdate) ALL NODES OFFSET 0;



--Query 05 & 07
CREATE PROJECTION __SCHEMA__.lineitem_DBD_seg 
(
 l_suppkey ENCODING RLE,
 l_orderkey ENCODING RLE,
 l_extendedprice ENCODING DELTAVAL,
 l_discount ENCODING RLE,
 l_shipdate ENCODING DELTAVAL
)
AS
 SELECT lineitem.l_suppkey,
        lineitem.l_orderkey,
        lineitem.l_extendedprice,
        lineitem.l_discount,
        lineitem.l_shipdate
 FROM __SCHEMA__.lineitem
 ORDER BY lineitem.l_suppkey,
          lineitem.l_orderkey,
          lineitem.l_discount,
          lineitem.l_extendedprice,
          lineitem.l_shipdate
SEGMENTED BY hash(lineitem.l_suppkey) ALL NODES OFFSET 0;


--Query 06
CREATE PROJECTION __SCHEMA__.lineitem_DBD_1_seg_MC_TPCH_INC1_b0
(
 l_quantity ENCODING RLE,
 l_extendedprice ENCODING DELTARANGE_COMP,
 l_discount ENCODING RLE,
 l_shipdate ENCODING RLE
)
AS
 SELECT lineitem.l_quantity,
        lineitem.l_extendedprice,
        lineitem.l_discount,
        lineitem.l_shipdate
 FROM __SCHEMA__.lineitem
 ORDER BY lineitem.l_shipdate,
          lineitem.l_quantity,
          lineitem.l_discount,
          lineitem.l_extendedprice
SEGMENTED BY hash(lineitem.l_extendedprice) ALL NODES OFFSET 0;


--Query 08
CREATE PROJECTION __SCHEMA__.lineitem_DBD_1_seg_MC_TPCH_INC1_v1_b0 /*+basename(lineitem_DBD_1_seg_MC_TPCH_INC1_v1),createtype(D)*/ 
(
 l_partkey ENCODING RLE,
 l_suppkey ENCODING COMMONDELTA_COMP,
 l_orderkey ENCODING RLE,
 l_extendedprice ENCODING DELTAVAL,
 l_discount ENCODING BLOCKDICT_COMP
)
AS
 SELECT lineitem.l_partkey,
        lineitem.l_suppkey,
        lineitem.l_orderkey,
        lineitem.l_extendedprice,
        lineitem.l_discount
 FROM __SCHEMA__.lineitem
 ORDER BY lineitem.l_partkey,
          lineitem.l_orderkey,
          lineitem.l_suppkey,
          lineitem.l_extendedprice
SEGMENTED BY hash(lineitem.l_suppkey) ALL NODES OFFSET 0;


--Query 10
CREATE PROJECTION __SCHEMA__.lineitem_q10 /*+createtype(D)*/ 
(
 l_orderkey ENCODING RLE,
 l_extendedprice ENCODING DELTARANGE_COMP,
 l_discount ENCODING RLE,
 l_returnflag ENCODING RLE
)
AS
 SELECT lineitem.l_orderkey,
        lineitem.l_extendedprice,
        lineitem.l_discount,
        lineitem.l_returnflag
 FROM __SCHEMA__.lineitem
 ORDER BY lineitem.l_returnflag,
          lineitem.l_orderkey,
          lineitem.l_discount,
          lineitem.l_extendedprice
UNSEGMENTED ALL NODES;


--Query 12
CREATE PROJECTION __SCHEMA__.lineitem_DBD_1_seg_MC_TPCH_INC1_v2_b0 /*+basename(lineitem_DBD_1_seg_MC_TPCH_INC1_v2),createtype(D)*/ 
(
 l_orderkey ENCODING RLE,
 l_shipdate ENCODING RLE,
 l_commitdate ENCODING COMMONDELTA_COMP,
 l_receiptdate ENCODING RLE,
 l_shipmode ENCODING RLE
)
AS
 SELECT lineitem.l_orderkey,
        lineitem.l_shipdate,
        lineitem.l_commitdate,
        lineitem.l_receiptdate,
        lineitem.l_shipmode
 FROM __SCHEMA__.lineitem
 ORDER BY lineitem.l_shipmode,
          lineitem.l_receiptdate,
          lineitem.l_orderkey,
          lineitem.l_shipdate,
          lineitem.l_commitdate
SEGMENTED BY hash(lineitem.l_receiptdate) ALL NODES OFFSET 0;
--Query 14


CREATE PROJECTION __SCHEMA__.lineitem_DBD_1_seg_MC_TPCH_INC1_v3_b0 /*+basename(lineitem_DBD_1_seg_MC_TPCH_INC1_v3),createtype(D)*/ 
(
 l_partkey ENCODING DELTARANGE_COMP,
 l_extendedprice ENCODING DELTAVAL,
 l_discount ENCODING RLE,
 l_shipdate ENCODING RLE
)
AS
 SELECT lineitem.l_partkey,
        lineitem.l_extendedprice,
        lineitem.l_discount,
        lineitem.l_shipdate
 FROM __SCHEMA__.lineitem
 ORDER BY lineitem.l_shipdate,
          lineitem.l_discount,
          lineitem.l_partkey,
          lineitem.l_extendedprice
SEGMENTED BY hash(lineitem.l_partkey) ALL NODES OFFSET 0;



CREATE PROJECTION __SCHEMA__.lineitem_DBD_1_seg_MC_TPCH_INC1_v5_b0 /*+basename(lineitem_DBD_1_seg_MC_TPCH_INC1_v5),createtype(D)*/ 
(
 l_partkey ENCODING RLE,
 l_quantity ENCODING BLOCKDICT_COMP,
 l_extendedprice ENCODING DELTAVAL
)
AS
 SELECT lineitem.l_partkey,
        lineitem.l_quantity,
        lineitem.l_extendedprice
 FROM __SCHEMA__.lineitem
 ORDER BY lineitem.l_partkey,
          lineitem.l_quantity,
          lineitem.l_extendedprice
SEGMENTED BY hash(lineitem.l_partkey) ALL NODES OFFSET 0;


--Query 17
CREATE PROJECTION __SCHEMA__.lineitem_DBD_1_seg_MC_TPCH_INC1_v5_b0 /*+basename(lineitem_DBD_1_seg_MC_TPCH_INC1_v5),createtype(D)*/ 
(
 l_partkey ENCODING RLE,
 l_quantity ENCODING BLOCKDICT_COMP,
 l_extendedprice ENCODING DELTAVAL
)
AS
 SELECT lineitem.l_partkey,
        lineitem.l_quantity,
        lineitem.l_extendedprice
 FROM __SCHEMA__.lineitem
 ORDER BY lineitem.l_partkey,
          lineitem.l_quantity,
          lineitem.l_extendedprice
SEGMENTED BY hash(lineitem.l_partkey) ALL NODES OFFSET 0;

--Query 18



CREATE PROJECTION __SCHEMA__.lineitem_DBD_2_seg_MC_TPCH_COMP_b0 /*+basename(lineitem_DBD_2_seg_MC_TPCH_COMP),createtype(D)*/ 
(
 l_linenumber ENCODING DELTARANGE_COMP,
 l_partkey ENCODING DELTAVAL,
 l_suppkey ENCODING DELTAVAL,
 l_orderkey ENCODING RLE,
 l_quantity ENCODING RLE,
 l_extendedprice ENCODING DELTARANGE_COMP,
 l_discount ENCODING RLE,
 l_tax ENCODING RLE,
 l_returnflag ENCODING RLE,
 l_linestatus ENCODING RLE,
 l_shipdate ENCODING DELTAVAL,
 l_commitdate ENCODING DELTAVAL,
 l_receiptdate ENCODING DELTAVAL,
 l_shipinstruct ENCODING RLE,
 l_shipmode ENCODING RLE,
 l_comment ENCODING ZSTD_FAST_COMP
)
AS
 SELECT lineitem.l_linenumber,
        lineitem.l_partkey,
        lineitem.l_suppkey,
        lineitem.l_orderkey,
        lineitem.l_quantity,
        lineitem.l_extendedprice,
        lineitem.l_discount,
        lineitem.l_tax,
        lineitem.l_returnflag,
        lineitem.l_linestatus,
        lineitem.l_shipdate,
        lineitem.l_commitdate,
        lineitem.l_receiptdate,
        lineitem.l_shipinstruct,
        lineitem.l_shipmode,
        lineitem.l_comment
 FROM __SCHEMA__.lineitem
 ORDER BY lineitem.l_linestatus,
          lineitem.l_returnflag,
          lineitem.l_shipinstruct,
          lineitem.l_orderkey,
          lineitem.l_shipmode,
          lineitem.l_tax,
          lineitem.l_discount,
          lineitem.l_quantity,
          lineitem.l_linenumber
SEGMENTED BY hash(lineitem.l_linenumber) ALL NODES OFFSET 0;



--Query 19
CREATE PROJECTION __SCHEMA__.lineitem_DBD_1_seg_MC_TPCH_INC1_v6_b0 /*+basename(lineitem_DBD_1_seg_MC_TPCH_INC1_v6),createtype(D)*/ 
(
 l_partkey ENCODING DELTARANGE_COMP,
 l_quantity ENCODING RLE,
 l_extendedprice ENCODING DELTARANGE_COMP,
 l_discount ENCODING RLE,
 l_shipinstruct ENCODING RLE,
 l_shipmode ENCODING RLE
)
AS
 SELECT lineitem.l_partkey,
        lineitem.l_quantity,
        lineitem.l_extendedprice,
        lineitem.l_discount,
        lineitem.l_shipinstruct,
        lineitem.l_shipmode
 FROM __SCHEMA__.lineitem
 ORDER BY lineitem.l_shipmode,
          lineitem.l_shipinstruct,
          lineitem.l_discount,
          lineitem.l_quantity,
          lineitem.l_partkey,
          lineitem.l_extendedprice
SEGMENTED BY hash(lineitem.l_partkey) ALL NODES OFFSET 0;


SELECT MARK_DESIGN_KSAFE(1);







select refresh('__SCHEMA__.lineitem');


-----------------------------------------------------------------------------
------ORDERS TABLE--------------------------------------------------------
-----------------------------------------------------------------------------
CREATE TABLE __SCHEMA__.orders (
    o_orderkey      INT         NOT NULL,
    o_custkey       INT         NOT NULL,
    o_orderstatus   VARCHAR(1)  NOT NULL,
    o_totalprice    DECIMAL(15,2) NOT NULL,
    o_orderdate     DATE        NOT NULL,
    o_orderpriority VARCHAR(15) NOT NULL,
    o_clerk         VARCHAR(15) NOT NULL,
    o_shippriority  INT         NOT NULL,
    o_comment       VARCHAR(79) NOT NULL
);

--Query 04
CREATE PROJECTION __SCHEMA__.orders_DBD_2_seg_MC_TPCH_INC
(
 o_orderkey ENCODING DELTARANGE_COMP,
 o_orderdate ENCODING RLE,
 o_orderpriority ENCODING RLE
)
AS
 SELECT orders.o_orderkey,
        orders.o_orderdate,
        orders.o_orderpriority
 FROM __SCHEMA__.orders
 ORDER BY orders.o_orderpriority,
          orders.o_orderdate,
          orders.o_orderkey
SEGMENTED BY hash(orders.o_orderkey) ALL NODES OFFSET 0;



-----Query 07 & 
CREATE PROJECTION __SCHEMA__.orders_DBD_3_seg_MC_TPCH_INC_b0
(
 o_orderkey ENCODING DELTARANGE_COMP,
 o_custkey ENCODING DELTAVAL,
 o_orderdate ENCODING RLE,
 o_shippriority ENCODING RLE
)
AS
 SELECT orders.o_orderkey,
        orders.o_custkey,
        orders.o_orderdate,
        orders.o_shippriority
 FROM __SCHEMA__.orders
 ORDER BY orders.o_orderdate,
          orders.o_shippriority,
          orders.o_orderkey
SEGMENTED BY hash(orders.o_orderkey) ALL NODES OFFSET 0;


--Query 10
CREATE PROJECTION __SCHEMA__.orders_q10
(
 o_orderkey ENCODING DELTARANGE_COMP,
 o_custkey ENCODING DELTAVAL,
 o_orderdate ENCODING RLE
)
AS
 SELECT orders.o_orderkey,
        orders.o_custkey,
        orders.o_orderdate
 FROM __SCHEMA__.orders
 ORDER BY orders.o_orderdate,
          orders.o_orderkey
SEGMENTED BY hash(orders.o_custkey) ALL NODES OFFSET 0;


-- Query 12
CREATE PROJECTION __SCHEMA__.orders_DBD_4_seg_MC_TPCH_COMP_b0 /*+basename(orders_DBD_4_seg_MC_TPCH_COMP),createtype(D)*/ 
(
 o_orderkey ENCODING DELTARANGE_COMP,
 o_custkey ENCODING DELTAVAL,
 o_orderstatus ENCODING RLE,
 o_totalprice ENCODING DELTAVAL,
 o_orderdate ENCODING RLE,
 o_orderpriority ENCODING RLE,
 o_clerk ENCODING ZSTD_FAST_COMP,
 o_shippriority ENCODING RLE,
 o_comment ENCODING ZSTD_FAST_COMP
)
AS
 SELECT orders.o_orderkey,
        orders.o_custkey,
        orders.o_orderstatus,
        orders.o_totalprice,
        orders.o_orderdate,
        orders.o_orderpriority,
        orders.o_clerk,
        orders.o_shippriority,
        orders.o_comment
 FROM __SCHEMA__.orders
 ORDER BY orders.o_shippriority,
          orders.o_orderstatus,
          orders.o_orderpriority,
          orders.o_orderdate,
          orders.o_orderkey
SEGMENTED BY hash(orders.o_orderkey) ALL NODES OFFSET 0;



-- Query 13 & 22
CREATE PROJECTION __SCHEMA__.orders_DBD_2_seg_MC_TPCH_INC1_v1_b0 /*+basename(orders_DBD_2_seg_MC_TPCH_INC1_v1),createtype(D)*/ 
(
 o_orderkey ENCODING DELTAVAL,
 o_custkey ENCODING RLE,
 o_comment ENCODING ZSTD_FAST_COMP
)
AS
 SELECT orders.o_orderkey,
        orders.o_custkey,
        orders.o_comment
 FROM __SCHEMA__.orders
 ORDER BY orders.o_custkey,
          orders.o_orderkey
SEGMENTED BY hash(orders.o_custkey) ALL NODES OFFSET 0;


SELECT MARK_DESIGN_KSAFE(1);

--Query 18
CREATE PROJECTION __SCHEMA__.orders_DBD_4_seg_MC_TPCH_COMP_b0 /*+basename(orders_DBD_4_seg_MC_TPCH_COMP),createtype(D)*/ 
(
 o_orderkey ENCODING DELTARANGE_COMP,
 o_custkey ENCODING DELTAVAL,
 o_orderstatus ENCODING RLE,
 o_totalprice ENCODING DELTAVAL,
 o_orderdate ENCODING RLE,
 o_orderpriority ENCODING RLE,
 o_clerk ENCODING ZSTD_FAST_COMP,
 o_shippriority ENCODING RLE,
 o_comment ENCODING ZSTD_FAST_COMP
)
AS
 SELECT orders.o_orderkey,
        orders.o_custkey,
        orders.o_orderstatus,
        orders.o_totalprice,
        orders.o_orderdate,
        orders.o_orderpriority,
        orders.o_clerk,
        orders.o_shippriority,
        orders.o_comment
 FROM __SCHEMA__.orders
 ORDER BY orders.o_shippriority,
          orders.o_orderstatus,
          orders.o_orderpriority,
          orders.o_orderdate,
          orders.o_orderkey
SEGMENTED BY hash(orders.o_orderkey) ALL NODES OFFSET 0;


SELECT MARK_DESIGN_KSAFE(1);


SELECT MARK_DESIGN_KSAFE(1);


select refresh('__SCHEMA__.orders');

----------------------------------------------------------------------------
------PARTSUPP TABLE------------------------------------------------------
----------------------------------------------------------------------------

CREATE TABLE __SCHEMA__.partsupp (
    ps_partkey    INT         NOT NULL,
    ps_suppkey    INT         NOT NULL,
    ps_availqty   INT         NOT NULL,
    ps_supplycost DECIMAL(15,2) NOT NULL,
    ps_comment    VARCHAR(199) NOT NULL
);






SELECT MARK_DESIGN_KSAFE(1);


DROP VIEW IF EXISTS __SCHEMA__.revenue0;
CREATE VIEW __SCHEMA__.revenue0 (supplier_no, total_revenue) AS
SELECT
    l_suppkey,
    SUM(l_extendedprice * (1 - l_discount))
FROM
    __SCHEMA__.lineitem
WHERE
    l_shipdate >= DATE '1996-01-01'
    AND l_shipdate <  DATE '1996-01-01' + INTERVAL '3 MONTH'
GROUP BY
    l_suppkey;
