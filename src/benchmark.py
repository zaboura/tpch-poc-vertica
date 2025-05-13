# benchmark.py
#!/usr/bin/env python
# -- coding: utf-8 --

import argparse
import logging
import re
import sys
import time
from lib import conf_parser
from lib.vertica_lib import VerticaLib  # updated import
from utility import logger


class VerticaBenchmark(object):
    def __init__(self):
        self.lib = VerticaLib()

    def parse_args(self):
        parser = argparse.ArgumentParser(description="benchmark args parser")
        parser.add_argument("-p", "--performance", dest="performance", action="store_true", default=False)
        parser.add_argument("-c", "--check_result", dest="check_result", action="store_true", default=False)
        parser.add_argument("-s", "--scale", dest="scale", type=int, default=100)
        parser.add_argument("-d", "--dataset", type=str, default="")
        parser.add_argument("-S", "--sql_file", type=str, default="")
        parser.add_argument("-q", "--quiet", dest="log_quiet", action="store_true", default=False)
        parser.add_argument("-v", "--verbose", dest="log_verbose", action="store_true", default=False)
        return parser

    def connect_vertica(self):
        self.lib.connect()

    def close_vertica(self):
        self.lib.close()

    def use_database(self, db_name):
        self.lib.execute_sql(f"USE {db_name}", "ddl")

    def sort_sql_list(self, sql_info_list):
        for sql_info_dict in sql_info_list:
            digit_part = re.sub(r"\D", "", sql_info_dict["file_name"])
            sql_info_dict["index"] = int(digit_part) if digit_part else 0
        sql_info_list.sort(key=lambda x: x["index"])

    def get_test_sql_dirs(self, sql_dir_name):
        test_sql_dirs = []
        sql_dirs = self.lib.get_query_sql_dirs()
        if not sql_dir_name or sql_dir_name == ".":
            test_sql_dirs.append(".")
        elif sql_dir_name == "all":
            test_sql_dirs.extend(sql_dirs)
        elif sql_dir_name in sql_dirs:
            test_sql_dirs.append(sql_dir_name)
        else:
            logging.error("Invalid dataset: %s. Valid options: %s", sql_dir_name, [".", "all"] + sql_dirs)
        return test_sql_dirs

    def test_parallel_performance(self, sql_dir_name, sql_file=None):
        self.connect_vertica()
        try:
            db_name = conf_parser.vertica_database
            self.use_database(db_name)

            test_sql_dirs = self.get_test_sql_dirs(sql_dir_name)
            logging.info("Testing SQL dirs: %s", ", ".join(test_sql_dirs))

            for sql_dir in test_sql_dirs:
                sql_list = self.lib.get_query_table_sqls(sql_dir)
                self.sort_sql_list(sql_list)

                for concurrency_num in conf_parser.concurrency_num_list:
                    for sql_dict in sql_list:
                        result = [sql_dict["file_name"]]
                        for parallel_num in conf_parser.parallel_num_list:
                            time_start = time.time()
                            for _ in range(int(concurrency_num)):
                                self.lib.execute_sql(sql_dict["sql"], "dml")
                            time_end = time.time()

                            duration = (time_end - time_start) / int(concurrency_num)
                            result.append(str(round(duration * 1000, 2)))
                            time.sleep(int(conf_parser.sleep_ms) / 1000.0)

                        print("\t".join(result))
        finally:
            self.close_vertica()

    def check_results(self, sql_dir_name, scale):
        self.connect_vertica()
        try:
            self.use_database(conf_parser.vertica_database)
            test_sql_dirs = self.get_test_sql_dirs(sql_dir_name)

            for sql_dir in test_sql_dirs:
                print("------ %s ------" % sql_dir)
                sql_list = self.lib.get_query_table_sqls(sql_dir)
                self.sort_sql_list(sql_list)

                for sql_dict in sql_list:
                    sql_file = sql_dict["file_name"]
                    query_res = self.lib.execute_sql(sql_dict["sql"], "dml")

                    if not query_res["status"]:
                        print("sql: %s. error: %s" % (sql_file, query_res["msg"]))
                        continue

                    base_result = self.lib.get_query_base_result(sql_dir, scale, sql_file)
                    if base_result is None:
                        logging.error("Base result missing for %s", sql_file)
                        continue

                    query_result = query_res["result"]
                    if len(query_result) != len(base_result):
                        print("sql: %s. row count mismatch. base: %s, query: %s"
                              % (sql_file, len(base_result), len(query_result)))
                        continue

                    mismatch_found = False
                    for i, row in enumerate(query_result):
                        actual = "\t".join(str(c) if c is not None else "NULL" for c in row)
                        expected = base_result[i]
                        if actual != expected:
                            print(f"sql: {sql_file} mismatch.\nexpected: {expected}\nactual: {actual}")
                            mismatch_found = True
                            break

                    if not mismatch_found:
                        print("sql: %s ok" % sql_file)
        finally:
            self.close_vertica()


if __name__ == '__main__':
    benchmark = VerticaBenchmark()
    args_parser = benchmark.parse_args()
    args = args_parser.parse_args()

    if args.log_quiet:
        logger.LOG_LEVEL = logging.WARN
    elif args.log_verbose:
        logger.LOG_LEVEL = logging.DEBUG
    logger.init_logging(level=logger.LOG_LEVEL)
    logging.info("benchmark args:%s", args)

    if args.performance and args.check_result:
        print("-c and -p should not be assigned at the same time.\n")
        args_parser.print_help()
        sys.exit(-1)
    elif args.performance:
        benchmark.test_parallel_performance(args.dataset, args.sql_file)
    elif args.check_result:
        benchmark.check_results(args.dataset, args.scale)
    else:
        print("missing -c or -p args.\n")
        args_parser.print_help()
        sys.exit(-1)
