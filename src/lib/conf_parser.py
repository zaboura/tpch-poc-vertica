#!/usr/bin/env python
# -- coding: utf-8 --
import configparser
import os
import sys

import config.config as project_config

if not os.path.exists(project_config.VERTICA_CONF):
    print("Vertica config file does not exist. file: %s" % project_config.VERTICA_CONF)
    sys.exit()

config = configparser.ConfigParser()
config.read(project_config.VERTICA_CONF)

# Vertica config
vertica_host = config.get("vertica", "host")
vertica_port = config.get("vertica", "port")
vertica_user = config.get("vertica", "user")
vertica_password = config.get("vertica", "password")
vertica_database = config.get("vertica", "database")
vertica_schema = config.get("vertica", "schema")
sleep_ms = config.get("vertica", "sleep_ms", fallback="1000")

# optional
parallel_num_string = config.get("vertica", "parallel_num", fallback="1")
parallel_num_list = parallel_num_string.split(",")
concurrency_num_string = config.get("vertica", "concurrency_num", fallback="1")
concurrency_num_list = concurrency_num_string.split(",")
num_of_queries = config.getint("vertica", "num_of_queries", fallback=1)

