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

echo "[INFO] Loading data into Vertica schema '${v_schema}' from directory: ${data_dir}"
echo "[INFO] Connecting to ${v_user}@${v_host}:${v_port}/${v_db}"

# Identify unique table prefixes: e.g., customer, lineitem, etc.
for base in $(ls "${data_dir}"/*.tbl* 2>/dev/null | sed -E 's/.*\/(.*)\.tbl.*/\1/' | sort -u); do
    echo "[INFO] ────────────────────────────────────────────────"
    echo "[INFO] Loading table: ${v_schema}.${base}"

    start=$(date +%s)

    for file in "${data_dir}/${base}.tbl"*; do
        echo "[INFO] Loading fragment: ${file}"

        vsql -h "$v_host" -p "$v_port" -U "$v_user" -w "$v_pass" -d "$v_db" -c \
          "COPY ${v_schema}.${base} FROM LOCAL '${file}' DELIMITER '|' NULL '' DIRECT;"
    done

    end=$(date +%s)
    duration=$((end - start))

    row_count=$(vsql -h "$v_host" -p "$v_port" -U "$v_user" -w "$v_pass" -d "$v_db" -At -c \
        "SELECT COUNT(*) FROM ${v_schema}.${base};")

    echo "[INFO] Load completed for ${v_schema}.${base} in ${duration}s"
    echo "[INFO] Total rows: ${row_count}"
done

echo "[INFO] ✅ All tables loaded successfully."
