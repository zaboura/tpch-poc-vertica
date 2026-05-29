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
schema=$(grep -w schema ${CONF_FILE} | awk '{print $2}')



run_query() {
    local query_label=$1
    local query=$2
    local query_output

    query="${query//__SCHEMA__/${schema}}"

    sync  # flush disk caches (optional)
    echo -ne "${query_label}\t" | tee -a result.csv

    # Warm-up phase (runs the query 3 times without measuring)
    for i in {1..3}; do
        if ! query_output=$(vsql -h "${v_host}" -p "${v_port}" -U "${user}" -w "${password}" -d "${database}" -c "${query}" 2>&1 > /dev/null); then
            echo "" | tee -a result.csv
            echo "[ERROR] ${query_label} failed during warm-up run ${i}" >&2
            echo "${query_output}" >&2
            exit 1
        fi
    done

    # Run and time the query TRIES times
    TRIES_TIME=0
    for i in $(seq 1 ${TRIES}); do
        START=$(date +%s%3N)  # Get start time in ms
        if ! query_output=$(vsql -h "${v_host}" -p "${v_port}" -U "${user}" -w "${password}" -d "${database}" -c "${query}" 2>&1 > /dev/null); then
            echo "" | tee -a result.csv
            echo "[ERROR] ${query_label} failed during measured run ${i}" >&2
            echo "${query_output}" >&2
            exit 1
        fi
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
}

read_sql_file() {
    local sql_file=$1
    local query=""
    local line

    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line#"${line%%[![:space:]]*}"}"
        [[ -z "$line" || "$line" =~ ^-- ]] && continue
        query+=" ${line}"
    done < "${sql_file}"

    echo "${query}"
}

# Header for CSV results
echo -e "SQL\tTime(ms)" | tee -a result.csv
Total=0

if [[ -z "$v_host" || -z "$user" || -z "$v_port" || -z "$password" || -z "$database" || -z "$schema" ]]; then
    echo "[ERROR] Missing Vertica config values from: $CONF_FILE"
    exit 1
fi

if [[ ! "$schema" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
    echo "[ERROR] Invalid schema name '$schema'. Use an unquoted Vertica identifier, for example: tpch or benchmark_tpch."
    exit 1
fi

if [[ $# -eq 0 ]]; then
    # Default: read each query from the single-file query list.
    query_file=${BIN_PATH}/../sql/tpch/query/tpch.single_file/tpch_query.sql

    while IFS= read -r query || [[ -n "$query" ]]; do
        [[ -z "$query" || "$query" =~ ^-- ]] && continue
        run_query "Q${QUERY_NUM}" "${query}"
        QUERY_NUM=$((QUERY_NUM + 1))
    done < "${query_file}"
else
    # Optional mode: each argument is a separate SQL file to benchmark.
    for sql_file in "$@"; do
        if [[ ! -f "$sql_file" ]]; then
            echo "[ERROR] SQL file does not exist: $sql_file"
            exit 1
        fi

        query=$(read_sql_file "$sql_file")
        if [[ -z "$query" ]]; then
            echo "[ERROR] SQL file has no executable query: $sql_file"
            exit 1
        fi

        run_query "$(basename "$sql_file" .sql)" "${query}"
    done
fi

# Final total
echo -e "Total\t$Total" | tee -a result.csv
