select
  __SCHEMA__.nation,
  o_year,
  sum(amount) as sum_profit
from
  (
    select
      n_name as __SCHEMA__.nation,
      extract(year from o_orderdate) as o_year,
      l_extendedprice * (1 - l_discount) - ps_supplycost * l_quantity as amount
    from
      __SCHEMA__.part,
      __SCHEMA__.supplier,
      __SCHEMA__.lineitem,
      __SCHEMA__.partsupp,
      __SCHEMA__.orders,
      __SCHEMA__.nation
    where
      s_suppkey = l_suppkey
      and ps_suppkey = l_suppkey
      and ps_partkey = l_partkey
      and p_partkey = l_partkey
      and o_orderkey = l_orderkey
      and s_nationkey = n_nationkey
      and p_name like '%green%'
  ) as profit
group by
  __SCHEMA__.nation,
  o_year
order by
  __SCHEMA__.nation,
  o_year desc;
