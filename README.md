# Vertica TPC-H Benchmark Guide

This repository provides scripts and SQL files for running a TPC-H style benchmark against a Vertica database. It includes Vertica-specific table creation, data loading, and benchmark execution scripts.

The normal workflow is:

1. Configure the Vertica connection.
2. Generate TPC-H `.tbl` data files.
3. Create the TPC-H schema and tables.
4. Load the generated data into Vertica.
5. Run the benchmark queries and review `result.csv`.

Run the commands below from the repository root unless noted otherwise.

## Project Layout

- `bin`: Shell scripts for data generation, table creation, data loading, and benchmark execution.
- `conf`: Vertica connection and benchmark configuration.
- `sql/tpch`: TPC-H DDL and query SQL files.
- `src`: Python helper code used by the table creation flow.
- `thirdparty/tpch-dbgen`: Bundled TPC-H `dbgen` utility used to generate benchmark data.

## Scripts

The main scripts are:

- `bin/gen_data/gen-tpch.sh`: Generates TPC-H `.tbl` data files.
- `bin/create_db_table.sh`: Creates the schema and tables from a selected DDL directory.
- `bin/load_data.sh`: Loads generated `.tbl*` files into Vertica with `COPY`.
- `bin/benchmark.sh`: Runs the TPC-H query suite and writes timings to `result.csv`.

## Prerequisites

The benchmark scripts expect these tools to already be available:

- A Bash-compatible shell.
- Vertica `vsql` on your `PATH`.
- `python3`.
- The Python package `vertica-python`.
- The TPC-H data generator binary at `thirdparty/tpch-dbgen/dbgen`.
- Access to an existing Vertica database.

This project does not create the Vertica database or install dependencies for you. Create the database and install/configure the required tools before running the benchmark.

If `thirdparty/tpch-dbgen/dbgen` is missing or not executable on your platform, build it from the `thirdparty/tpch-dbgen` directory before generating data.

## Configure Vertica

Edit `conf/vertica.conf` so it points to your Vertica cluster:

```bash
nano conf/vertica.conf
```

The scripts read these values from the `[vertica]` section:

- `host`: Vertica host or IP address.
- `port`: Vertica port, usually `5433`.
- `user`: Vertica user.
- `password`: Password for the Vertica user.
- `database`: Existing Vertica database to connect to.
- `schema`: Schema used for the TPC-H tables, for example `tpch` or `benchmark_tpch`.
- `ssl`: `True` or `False`.

Example:

```ini
[vertica]
host: <vertica-host>
port: 5433
user: <vertica-user>
password: <vertica-password>
database: <vertica-database>
schema: <vertica-schema>
ssl: False
```

Use an unquoted Vertica identifier for `schema`: letters, numbers, and underscores only, starting with a letter or underscore. The bundled SQL files may contain `tpch` as the schema name, but the create-table and benchmark scripts replace those references with the schema configured here at runtime.

## Generate TPC-H Data

Generate data with:

```bash
sh bin/gen_data/gen-tpch.sh <scale_gb> <data_dir>
```

For a 100 GB dataset:

```bash
sh bin/gen_data/gen-tpch.sh 100 data_100
```

The script writes TPC-H `.tbl` files under the data directory. For larger scale factors, some large tables may be split into multiple `.tbl*` fragments.

Generated `data_*` directories are ignored by Git.

The `gen-tpch.sh` script is a convenience wrapper around `thirdparty/tpch-dbgen/dbgen`. `tpch-dbgen`/`dbgen` is the TPC-H data generator associated with the Transaction Processing Performance Council (TPC).

## Create Tables

Create the schema and tables with:

```bash
sh bin/create_db_table.sh <ddl_dir>
```

For the default 100 GB DDL:

```bash
sh bin/create_db_table.sh ddl_100
```

Available DDL directories under `sql/tpch` include:

- `ddl.original`: Original table definitions with column order intended to match generated data.
- `ddl_100`: DDL for a 100 GB benchmark.
- `ddl_100.single_table`: Same 100 GB table definitions split into one file per table.
- `ddl_500`: DDL for a 500 GB benchmark.
- `ddl_1000`: DDL for a 1 TB benchmark.
- `ddl_opt`: Optimized/experimental Vertica DDL with projections and segmentation.

Important DDL note: if you want to optimize the benchmark by changing table layouts, projections, segmentation, encodings, partitioning, or column order, update the table definitions before creating the tables. The table creation flow automatically maps `tpch` schema references in DDL files to the schema from `conf/vertica.conf`, but it does not redesign table layouts for you. The load script uses `COPY` without an explicit column list, so the table definitions must stay compatible with the generated `.tbl` file layout and with the benchmark queries.

## Load Data

Load generated data into Vertica with:

```bash
sh bin/load_data.sh <data_dir>
```

For the 100 GB example:

```bash
sh bin/load_data.sh data_100
```

The load script scans the data directory for `.tbl*` files and loads each table into the configured schema with a command equivalent to:

```sql
COPY <schema>.<table> FROM LOCAL '<file>' DELIMITER '|' NULL '' DIRECT;
```

After each table load, the script prints the elapsed load time and row count.

## Run the Benchmark

Run the benchmark query suite with:

```bash
sh bin/benchmark.sh
```

The benchmark script reads queries from:

```text
sql/tpch/query/tpch.single_file/tpch_query.sql
```

For each query, it runs:

- 3 warm-up executions that are not measured.
- 3 measured executions.

The recorded time is the average of the measured executions in milliseconds.

## Results

Benchmark results are written to:

```text
result.csv
```

The file is created in the current working directory. If you run `sh bin/benchmark.sh` from the repository root, the result file is:

```text
./result.csv
```

`result.csv` is overwritten at the start of every benchmark run and is ignored by Git. Copy or rename it before running another benchmark if you want to keep historical results.

## Third-party Components

TPC-H data generation uses the bundled `thirdparty/tpch-dbgen` utility. `tpch-dbgen`/`dbgen` is the TPC-H data generator associated with the Transaction Processing Performance Council (TPC).
