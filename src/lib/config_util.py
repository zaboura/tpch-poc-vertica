#!/usr/bin/env python
# -- coding: utf-8 --

import logging
import os

import config.config as project_config
from config import columns_config


class ConfigUtil(object):
    """
    Utility class for handling configuration-related operations.
    Provides methods to retrieve directories, set benchmarks, and fetch table-specific configurations.
    """

    @staticmethod
    def get_sql_dir():
        """
        Get the SQL root directory for the current benchmark.
        Combines the SQL root path with the selected benchmark name.
        """
        return os.path.join(project_config.SQL_ROOT, project_config.BENCHMARK)

    @staticmethod
    def get_result_dir():
        """
        Get the result directory for the current benchmark.
        Combines the result root path with the selected benchmark name.
        """
        return os.path.join(project_config.RESULT_ROOT, project_config.BENCHMARK)

    @staticmethod
    def set_benchmark(benchmark_name):
        """
        Set the benchmark name used throughout the project.
        Validates the benchmark name against the list of supported benchmarks.
        Logs an error if the benchmark name is invalid.
        """
        if benchmark_name not in project_config.BENCHMARKS:
            logging.error("Invalid benchmark name '%s'. Must be one of: %s", benchmark_name, project_config.BENCHMARKS)
        project_config.BENCHMARK = benchmark_name

    @staticmethod
    def get_columns(table_name):
        """
        Retrieve column names for a given table from the configuration.
        Looks up the column configuration for the current benchmark and table.
        Returns an empty list if no columns are defined for the table.
        """
        table_columns = columns_config.columns.get(project_config.BENCHMARK, {})
        return table_columns.get(table_name, [])

    @staticmethod
    def get_concurrency_num(table_name):
        """
        Retrieve the concurrency number for loading a table.
        Defaults to 1 if no specific concurrency configuration is found.
        Logs the concurrency number for the table.
        """
        concurrency_num = 1
        concurrency_load_config = project_config.CONCURRENCY_LOAD_CONFIG.get(project_config.BENCHMARK, {})
        if concurrency_load_config and table_name in concurrency_load_config:
            concurrency_num = concurrency_load_config[table_name]
            logging.info("Concurrency load number for table '%s' is %d.", table_name, concurrency_num)
        else:
            logging.info("Concurrency load number for table '%s' not set. Using default: 1.", table_name)
        return concurrency_num
