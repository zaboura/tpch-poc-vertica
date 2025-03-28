#!/bin/bash

# usage for the script
usage()
{
    # Display usage instructions for the script
    echo -e "$(basename "$0") \033[49;32;1m data_size data_dir \033[0m"
    echo -e '\033[1m[USAGE]\033[0m'
    echo -e '    Gens tpch data at the specified size under the specified data directory.'
    echo -e '\033[1m[OPTIONS]\033[0m'
    echo -e '    \033[49;32;1m-h\033[0m : print this help.'
    echo -e '    \033[49;32;1mdata_size\033[0m : 1 for 1GB, 2 for 2GB, ...'
    echo -e '    \033[49;32;1mdata_dir\033[0m : data directory to store all the generated table data,'\
            'it will be created if not exist'
    echo -e '\033[1m[RETURN]\033[0m'
}

# Check if the required arguments are provided or if help is requested
if [[ $# -lt 2 ]] || [[ "$1" == "-h" ]]; then
    usage
    exit 1
fi

# Get the directory of the current script
_GEN_FILE_DIR_=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Source common configuration variables
. "${_GEN_FILE_DIR_}"/../common_info.sh

# Path to the tpch-dbgen tool
dbgen_path=${PROJECT_ROOT}/thirdparty/tpch-dbgen
# Maximum chunk size for a file in GB
FILE_CHUNK_SIZE=5

################################################################################
# Parse input arguments
# Data size in GB
size=$1
# Directory to store generated data
data_dir=$2

# Default to 1GB if size is not provided
if [[ -z "${size}" ]]; then
    size=1
else
    size=$((size + 0))
fi

# Convert data_dir to an absolute path
if [[ -z "${data_dir}" ]];then
    data_dir=$(pwd)
elif [[ ! "${data_dir:0:1}" == "/" ]];then
    data_dir="$(pwd)/${data_dir}"
fi
mkdir -p "${data_dir}"  # Create the directory if it doesn't exist

echo "[INFO] gen ${size}GB data under ${data_dir}"

################################################################################
# Define table names and their corresponding abbreviations
table_names=("customer" "lineitem" "nation" "orders" "parts" "partsupp" "region" "suppliers")
tables=(     "c"        "L"        "n"      "O"      "P"     "S"        "r"      "s")

# Calculate chunk numbers for each table based on size and FILE_CHUNK_SIZE
pl=$((size / FILE_CHUNK_SIZE))
parts=($((pl / 20))  # customer
       $((pl / 1))   # lineitem
       1             # nation
       $((pl / 5))   # orders
       $((pl / 20))  # parts
       $((pl / 5))   # partsupp
       1             # region
       $((pl / 500)) # suppliers
)

# Generate data for each table
echo "[INFO] generate data..." >&2
cd "${data_dir}" || exit

for ((ti=0; ti<${#tables[@]}; ti++))
do
    table_name=${table_names[$ti]}  # Full table name
    table=${tables[$ti]}            # Abbreviation
    part_num=${parts[$ti]}          # Number of parts to generate
    echo "[INFO] gen data of table: ${table_name}" >&2

    # Ensure at least one part is generated
    if [[ ${part_num} -le 0 ]];then
        part_num=1
    fi

    # Generate data in parts if necessary
    for i in $(seq 1 ${part_num})
    do
        if [[ ${part_num} -gt 1 ]];then
            echo "[INFO] gen <$i>th part data of table: ${table_name}"
            "${dbgen_path}"/dbgen -s ${size} -C ${part_num} -S $i -b "${dbgen_path}"/dists.dss -T ${table}
        else
            "${dbgen_path}"/dbgen -s ${size} -C 1 -b "${dbgen_path}"/dists.dss -T "${table}"
        fi
    done
done
cd "${_GEN_FILE_DIR_}" || exit

# Display the size of generated files
du -sh "${data_dir}"/*.tbl*
echo "[INFO] Data generation completed."
