# db_table_operation.py
#!/usr/bin/env python
# -- coding: utf-8 --

import argparse
import logging
import os
import sys

from lib import conf_parser
from lib.vertica_lib import VerticaLib
from lib.config_util import ConfigUtil
from utility import logger


class VerticaDbTableOperation(object):
    def __init__(self):
        self.lib = VerticaLib()

    def connect_vertica(self):
        self.lib.connect()

    def close_vertica(self):
        self.lib.close()

    def create_database(self, db_name):
        return self.lib.create_database(db_name)

    def use_database(self, db_name):
        self.lib.use_database(db_name)

    def create_db_table(self, data_dir_path):
        self.connect_vertica()
        try:
            schema = conf_parser.vertica_schema
            self.lib.create_schema(schema)

            ddl_sqls = self.lib.get_create_db_table_sqls(data_dir_path)
            if not ddl_sqls:
                logging.error("No valid SQL file under directory: %s", data_dir_path)

            for sql_dict in ddl_sqls:
                sql_file_path = os.path.join(data_dir_path, sql_dict["file_path"])
                res = self.lib.execute_sql(sql_dict["sql"], "ddl")
                if res is None:
                    logging.error("Failed to create table. SQL: %s", sql_file_path)
                elif not res["status"]:
                    logging.warning("Create table error. SQL: %s, msg: %s", sql_file_path, res["msg"])
                else:
                    logging.info("Create table success. SQL: %s", sql_file_path)
        finally:
            self.close_vertica()


    # def flat_insert(self):
    #     self.connect_vertica()
    #     try:
    #         self.use_database(conf_parser.vertica_database)
    #         insert_sqls = self.lib.get_flat_insert_sqls()
    #         for sql_dict in insert_sqls:
    #             print("sql: %s start" % sql_dict["file_name"])
    #             res = self.lib.execute_sql(sql_dict["sql"], "dml")
    #             if res is None or not res["status"]:
    #                 print("sql: %s error, msg: %s" % (sql_dict["file_name"], res["msg"]))
    #             else:
    #                 print("sql: %s success" % sql_dict["file_name"])
    #     finally:
    #         self.close_vertica()

    def parse_args(self):
        parser = argparse.ArgumentParser(prog="db_table_operation.py",
                                         description="Vertica DB/Table Operation CLI")
        parser.add_argument("-q", "--quiet", dest="log_quiet", action="store_true", default=False)
        parser.add_argument("-v", "--verbose", dest="log_verbose", action="store_true", default=False)

        subparsers = parser.add_subparsers(dest="operation_type", help="Available operations")

        parser_create = subparsers.add_parser("create", help="create tables")
        parser_create.add_argument("sql_dir", type=str, help="SQL directory for CREATE TABLE")

        parser_flat_insert = subparsers.add_parser("flat_insert", help="flat insert data")
        return parser


if __name__ == '__main__':
    operation = VerticaDbTableOperation()
    args_parser = operation.parse_args()
    args = args_parser.parse_args()

    if args.log_quiet:
        logger.LOG_LEVEL = logging.WARN
    elif args.log_verbose:
        logger.LOG_LEVEL = logging.DEBUG
    logger.init_logging(level=logger.LOG_LEVEL)
    logging.debug("args: %s", args)

    if args.operation_type == "create":
        operation.create_db_table(args.sql_dir)
    # elif args.operation_type == "flat_insert":
    #     operation.flat_insert()
    elif not args.operation_type:
        logging.error("Missing operation type.")
        args_parser.print_help()
    else:
        logging.error("Unknown operation type: %s", args.operation_type)
