## 🧪 Vertica TPC-H Benchmark Guide

This guide walks you through running a TPC-H performance benchmark test on Vertica using the `tpch-poc` framework.

---

### 1. 📦 Generate TPC-H Data

Unzip the TPC-H benchmark package and generate the dataset:

```bash
unzip tpch-poc-1.0
cd tpch-poc-1.0

# Replace 100 with the desired scale in GB (e.g., 50, 100, 1000)
sh bin/gen_data/gen-tpch.sh 100 data_100
```

---

### 2. 🏗️ Create Table Structure in Vertica

Edit the Vertica configuration file to point to your cluster:

```bash
nano conf/vertica.conf
```

Update the following fields:
- `host`: IP address or hostname of your Vertica node
- `port`: Vertica server port (default is usually `5433`)
- `user` and `password` if required

Then, create the database tables:

```bash
sh bin/create_db_table.sh ddl_100
```

---

### 3. 📥 Load Data into Vertica

Import the previously generated dataset into Vertica:

```bash
sh bin/load_data.sh data_100
```

---

### 4. 🚀 Run the Benchmark

Execute the TPC-H benchmark suite:

```bash
sh bin/benchmark.sh
```

---

✅ You're all set! Monitor the output to analyze Vertica’s performance with your selected dataset size.
