#!/usr/bin/env python
# -- coding: utf-8 --

import os

# List of supported benchmarks
BENCHMARKS = ["ssb", "tpch"]

# Default benchmark to test
BENCHMARK = "tpch"

# Define the root path of the project
PROJECT_ROOT_PATH = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "../.."))

# Path to Vertica's configuration file
VERTICA_CONF = os.path.join(PROJECT_ROOT_PATH, "conf/vertica.conf")

# Root directory containing all SQL scripts
SQL_ROOT = os.path.join(PROJECT_ROOT_PATH, "sql")

# Directory to store all results
RESULT_ROOT = os.path.join(PROJECT_ROOT_PATH, "result")

################################################################################
# Load configuration information for TPCH benchmark

# Concurrency configuration for loading TPCH tables
TPCH_CONCURRENCY_LOAD_CONFIG = {
    "lineitem": 10,  # Number of parallel processes for the 'lineitem' table
    "orders": 5      # Number of parallel processes for the 'orders' table
}

# General concurrency configuration for loading big tables in parallel
CONCURRENCY_LOAD_CONFIG = {
    "tpch": TPCH_CONCURRENCY_LOAD_CONFIG  # Specific configuration for TPCH benchmark
}
