# vertica_lib.py
#!/usr/bin/env python
# -- coding: utf-8 --

import logging
import os
import random
import re
import time

import vertica_python

from .config_util import ConfigUtil
from . import conf_parser


class VerticaException(Exception):
    def __init__(self, value):
        self.value = value

    def __str__(self):
        return repr(self.value)


class VerticaLib(object):
    def __init__(self):
        self.conn = None
        self.cursor = None

        self.host = conf_parser.vertica_host
        self.port = conf_parser.vertica_port
        self.user = conf_parser.vertica_user
        self.password = conf_parser.vertica_password
        self.database = conf_parser.vertica_database
        self.schema = conf_parser.vertica_schema
        self.ssl = conf_parser.vertica_ssl

        self.base_sql_file_dir = ConfigUtil.get_sql_dir()
        self.query_sql_dir = os.path.join(self.base_sql_file_dir, "query")
        self.create_db_table_sql_dir = self.base_sql_file_dir
        self.flat_insert_sql_dir = os.path.join(self.base_sql_file_dir, "insert")
        self.result_file_dir = ConfigUtil.get_result_dir()

    def connect(self):
        conn_info = {
            'host': self.host,
            'port': self.port,
            'user': self.user,
            'database': self.database,
            'ssl': self.ssl
        }
        if self.password:
            conn_info['password'] = self.password
        self.conn = vertica_python.connect(**conn_info)
        self.cursor = self.conn.cursor()

    def close(self):
        if self.cursor:
            self.cursor.close()
        if self.conn:
            self.conn.close()
            
    def validate_schema_name(self, schema_name):
        schema = schema_name.strip()
        if not re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", schema):
            raise VerticaException(
                "Invalid schema name '%s'. Use an unquoted Vertica identifier, for example: tpch or benchmark_tpch."
                % schema
            )
        return schema

    def create_schema(self, schema_name):
        schema = self.validate_schema_name(schema_name)
        return self.execute_sql(f"CREATE SCHEMA IF NOT EXISTS {schema}", "ddl")

    def apply_configured_schema(self, sql):
        schema = self.validate_schema_name(self.schema)
        return sql.replace("__SCHEMA__", schema)


    def execute_sql(self, sql, sql_type):
        try:
            self.cursor.execute(sql)
            if sql_type == "ddl":
                self.conn.commit()
                return {"status": True, "msg": "DDL executed"}
            elif sql_type == "dml":
                rows = self.cursor.fetchall()
                return {"status": True, "result": rows, "msg": "DML fetched"}
            else:
                return {"status": False, "msg": "Unknown SQL type"}
        except Exception as e:
            return {"status": False, "msg": str(e)}

    def get_sql_from_file(self, sql_path):
        with open(sql_path, 'r') as f:
            sql = ""
            for line in f:
                line = line.strip()
                if not line.startswith("--"):
                    sql += " " + line
        return self.apply_configured_schema(sql)

    def get_sqls_from_dir(self, dir_path):
        logging.info("Loading SQLs from dir: %s", dir_path)
        sql_list = []

        if not os.path.isdir(dir_path):
            logging.error("Not a valid directory: %s", dir_path)
            return sql_list

        for file in os.listdir(dir_path):
            if file.startswith(".") or not file.endswith(".sql"):
                continue
            file_path = os.path.join(dir_path, file)
            if not os.path.isfile(file_path):
                continue
            sql = self.get_sql_from_file(file_path)
            sql_list.append({
                "file_name": file.split(".")[0],
                "file_path": file_path,
                "sql": sql
            })
        return sql_list

    def get_query_table_sqls(self, dir_name):
        query_dir = os.path.abspath(os.path.join(self.query_sql_dir, dir_name))
        return self.get_sqls_from_dir(query_dir)

    def get_create_db_table_sqls(self, dir_name):
        dir_path = os.path.abspath(os.path.join(self.create_db_table_sql_dir, dir_name))
        return self.get_sqls_from_dir(dir_path)

    def get_flat_insert_sqls(self):
        return self.get_sqls_from_dir(self.flat_insert_sql_dir)

    def get_query_sql_dirs(self):
        logging.debug("Scanning subdirectories in query dir: %s", self.query_sql_dir)
        dirs = [d for d in os.listdir(self.query_sql_dir)
                if os.path.isdir(os.path.join(self.query_sql_dir, d))]
        return dirs or ["."]

    def get_query_base_result(self, sql_dir, scale, file_name):
        result_file_name = "%s.sql.res" % file_name
        result_file_path = os.path.join(self.result_file_dir, str(scale), sql_dir, result_file_name)
        if not os.path.isfile(result_file_path):
            return None
        with open(result_file_path, "r") as f:
            return [line.strip() for line in f]

    def get_load_data_paths(self, data_dir_path):
        load_data_paths = {}
        for file in os.listdir(data_dir_path):
            if file.startswith("."):
                continue
            path = os.path.join(data_dir_path, file)
            name = file.split(".")[0]
            load_data_paths.setdefault(name, []).append(path)
        return load_data_paths
