#!/bin/bash

set -e

if [[ $# -ne 1 ]]; then
    echo "[USAGE] $(basename "$0") <data_dir>"
    exit 1
fi

data_dir=$1
if [[ ! -d "$data_dir" ]]; then
    echo "[ERROR] Data directory '$data_dir' does not exist."
    exit 1
fi

BIN_PATH=$(cd "$(dirname "$0")"; pwd)
CONF_FILE="${BIN_PATH}/../conf/vertica.conf"

v_host=$(grep -w host "${CONF_FILE}" | awk '{print $2}')
v_port=$(grep -w port "${CONF_FILE}" | awk '{print $2}')
v_user=$(grep -w user "${CONF_FILE}" | awk '{print $2}')
v_pass=$(grep -w password "${CONF_FILE}" | awk '{print $2}')
v_db=$(grep -w database "${CONF_FILE}" | awk '{print $2}')
v_schema=$(grep -w schema "${CONF_FILE}" | awk '{print $2}')

if [[ -z "$v_host" || -z "$v_user" || -z "$v_port" || -z "$v_db" || -z "$v_schema" ]]; then
    echo "[ERROR] Missing Vertica config values from: $CONF_FILE"
    exit 1
fi

if [[ ! "$v_schema" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
    echo "[ERROR] Invalid schema name '$v_schema'. Use an unquoted Vertica identifier, for example: tpch or benchmark_tpch."
    exit 1
fi

echo "[INFO] Loading data into Vertica schema '${v_schema}' from directory: ${data_dir}"
echo "[INFO] Connecting to ${v_user}@${v_host}:${v_port}/${v_db}"

vsql_args=(-h "$v_host" -p "$v_port" -U "$v_user" -d "$v_db")

run_vsql() {
    if [[ -n "$v_pass" ]]; then
        VSQL_PASSWORD="$v_pass" vsql "${vsql_args[@]}" "$@"
    else
        vsql "${vsql_args[@]}" "$@"
    fi
}

is_allowed_table() {
    case "$1" in
        customer|lineitem|nation|orders|part|partsupp|region|supplier)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Identify unique table prefixes: e.g., customer, lineitem, etc.
for base in $(ls "${data_dir}"/*.tbl* 2>/dev/null | sed -E 's/.*\/(.*)\.tbl.*/\1/' | sort -u); do
    if ! is_allowed_table "$base"; then
        echo "[ERROR] Unsafe table name derived from file: $base"
        exit 1
    fi

    echo "[INFO] ────────────────────────────────────────────────"
    echo "[INFO] Loading table: ${v_schema}.${base}"

    start=$(date +%s)

    for file in "${data_dir}/${base}.tbl"*; do
        if [[ "$file" == *"'"* ]]; then
            echo "[ERROR] Unsafe data file path contains a single quote: $file"
            exit 1
        fi

        echo "[INFO] Loading fragment: ${file}"

        run_vsql -c \
          "COPY ${v_schema}.${base} FROM LOCAL '${file}' DELIMITER '|' NULL '' DIRECT;"
    done

    end=$(date +%s)
    duration=$((end - start))

    row_count=$(run_vsql -At -c \
        "SELECT COUNT(*) FROM ${v_schema}.${base};")

    echo "[INFO] Load completed for ${v_schema}.${base} in ${duration}s"
    echo "[INFO] Total rows: ${row_count}"
done

echo "[INFO] ✅ All tables loaded successfully."
