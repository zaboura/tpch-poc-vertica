#!/bin/bash

# Exit on any error
set -e

# Resolve script directory and config path
BIN_PATH=$(dirname "$0")
BIN_PATH=$(cd "${BIN_PATH}"; pwd)
CONF_FILE=${BIN_PATH}/../conf/vertica.conf

# Set initial values
QUERY_NUM=1
TRIES=3

touch result.csv
truncate -s0 result.csv

# Read Vertica config values from conf file
v_host=$(grep -w host ${CONF_FILE} | awk '{print $2}')
v_port=$(grep -w port ${CONF_FILE} | awk '{print $2}')
user=$(grep -w user ${CONF_FILE} | awk '{print $2}')
password=$(grep -w password ${CONF_FILE} | awk '{print $2}')
database=$(grep -w database ${CONF_FILE} | awk '{print $2}')



# SQL file containing queries (one per line)
query_file=${BIN_PATH}/../sql/tpch/query/tpch.single_file/tpch_query.sql

# Header for CSV results
echo -e "SQL\tTime(ms)" | tee -a result.csv
Total=0

if [[ -z "$v_host" || -z "$user" || -z "$v_port" || -z "$password" || -z "$database" ]]; then
    echo "[ERROR] Missing Vertica config values from: $CONF_FILE"
    exit 1
fi

# Read each query from the SQL file
while read -r query; do
    # Skip empty lines or comment lines
    [[ -z "$query" || "$query" =~ ^-- ]] && continue

    sync  # flush disk caches (optional)
    echo -ne "Q$QUERY_NUM\t" | tee -a result.csv

    # Warm-up phase (runs the query 3 times without measuring)
    for i in {1..3}; do
        vsql -h ${v_host} -p ${v_port} -U ${user} -w ${password} -d ${database} -c "${query}" > /dev/null 2>&1
    done

    # Run and time the query TRIES times
    TRIES_TIME=0
    for i in $(seq 1 $TRIES); do
        START=$(date +%s%3N)  # Get start time in ms
        vsql -h ${v_host} -p ${v_port} -U ${user} -w ${password} -d ${database} -c "${query}" > /dev/null 2>&1
        END=$(date +%s%3N)    # Get end time in ms
        DIFF=$((END - START))
        TRIES_TIME=$((TRIES_TIME + DIFF))
    done

    # Calculate average execution time in ms
    TRIES_TIME_AVG=$((TRIES_TIME / TRIES))
    echo -n "${TRIES_TIME_AVG}" | tee -a result.csv

    # Update total time
    Total=$((Total + TRIES_TIME_AVG))
    echo "" | tee -a result.csv

    # Increment query counter
    QUERY_NUM=$((QUERY_NUM + 1))
done < ${query_file}

# Final total
echo -e "Total\t$Total" | tee -a result.csv