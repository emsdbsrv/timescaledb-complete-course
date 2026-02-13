 **Lesson_04_Simulating_High_Volume_Inserts** demo.

It:

* Assumes PostgreSQL 17 + TimescaleDB are already installed and working
* Uses `psql -d db_name -c "..."` command style everywhere
* Includes cleanup before starting
* Includes cleanup at the end
* Is GitHub `README.md` ready
* Contains detailed explanation for every step

---

# Lesson_04_Simulating_High_Volume_Inserts

## Complete High-Volume Ingestion Lab

PostgreSQL 17 + TimescaleDB Workload Simulation

---

## Prerequisites

Before starting this lab, ensure:

* PostgreSQL 17 is installed and running
* TimescaleDB is installed
* `shared_preload_libraries = 'timescaledb'` is configured
* TimescaleDB extension loads correctly

Verify:

```bash
psql -d postgres -c "SHOW shared_preload_libraries;"
```

Expected output:

```
timescaledb
```

---

# PART 1 — Verify Clean Environment

We start by ensuring no previous objects exist.

---

## Step 1: Drop Existing Lab Database (If Any)

```bash
psql -d postgres -c "DROP DATABASE IF EXISTS ts_ingest_lab;"
```

### Explanation

* Ensures previous runs do not interfere.
* Keeps the lab reproducible.
* Prevents duplicate schema or hypertable conflicts.

---

# PART 2 — Create Fresh Lab Database

---

## Step 2: Create Database

```bash
psql -d postgres -c "CREATE DATABASE ts_ingest_lab;"
```

---

## Step 3: Enable TimescaleDB Extension

```bash
psql -d ts_ingest_lab -c "CREATE EXTENSION IF NOT EXISTS timescaledb;"
```

### Explanation

* Loads TimescaleDB into the lab database.
* Enables hypertables and time-series optimizations.

---

# PART 3 — Create High-Volume Table

---

## Step 4: Create Schema

```bash
psql -d ts_ingest_lab -c "CREATE SCHEMA ingest_lab;"
```

### Explanation

* Organizes lab objects.
* Keeps database structured.

---

## Step 5: Create Time-Series Table (Correct Primary Key Design)

⚠ The partition column must be part of the primary key.

```bash
psql -d ts_ingest_lab -c "
CREATE TABLE ingest_lab.iot_metrics (
    id BIGINT NOT NULL,
    device_id INT NOT NULL,
    recorded_at TIMESTAMPTZ NOT NULL,
    cpu_usage DOUBLE PRECISION,
    memory_usage DOUBLE PRECISION,
    PRIMARY KEY (id, recorded_at)
);
"
```

### Why Composite Primary Key?

TimescaleDB requires:

* The partition column (`recorded_at`)
* Must be included in any UNIQUE constraint

This avoids the hypertable unique index error.

---

# PART 4 — Convert to Hypertable

---

## Step 6: Create Hypertable

```bash
psql -d ts_ingest_lab -c "
SELECT create_hypertable(
    'ingest_lab.iot_metrics',
    'recorded_at'
);
"
```

### Definition

A hypertable is a logical abstraction over multiple time-partitioned chunks.

TimescaleDB automatically:

* Creates physical chunk tables
* Routes inserts to correct chunk
* Uses chunk exclusion during queries

---

# PART 5 — Simulate High-Volume Inserts

---

## Step 7: Insert 1,000,000 Rows

```bash
psql -d ts_ingest_lab -c "
INSERT INTO ingest_lab.iot_metrics
SELECT generate_series(1,1000000),
       (random()*500)::int,
       NOW() - (random()*600000 || ' seconds')::interval,
       random()*100,
       random()*100;
"
```

### What This Simulates

* IoT device telemetry
* Observability metrics
* Monitoring workload
* Real-world ingestion pattern

Timescale automatically:

* Distributes rows across chunks
* Creates new chunks as needed

---

# PART 6 — Validate Data

---

## Step 8: Verify Row Count

```bash
psql -d ts_ingest_lab -c "
SELECT COUNT(*) FROM ingest_lab.iot_metrics;
"
```

Expected output:

```
1000000
```

---

## Step 9: Inspect Chunk Creation

```bash
psql -d ts_ingest_lab -c "
SELECT hypertable_name, chunk_name
FROM timescaledb_information.chunks
WHERE hypertable_name = 'iot_metrics';
"
```

### Explanation

Shows internal chunk tables automatically created by TimescaleDB.

---

# PART 7 — Performance Testing

---

## Step 10: Run Time-Based Query

```bash
psql -d ts_ingest_lab -c "
EXPLAIN ANALYZE
SELECT *
FROM ingest_lab.iot_metrics
WHERE recorded_at > NOW() - INTERVAL '1 hour';
"
```

### What Happens Internally

* Timescale performs chunk exclusion
* Only recent chunks are scanned
* Query latency remains low even with 1M rows

---

# PART 8 — Optional Index Optimization

---

## Step 11: Create Descending Time Index

```bash
psql -d ts_ingest_lab -c "
CREATE INDEX idx_recorded_desc
ON ingest_lab.iot_metrics(recorded_at DESC);
"
```

### Why This Helps

* Optimizes dashboards
* Speeds up recent data queries
* Reduces sort overhead

---

# PART 9 — WAL Awareness (Optional Monitoring)

High-volume inserts generate WAL traffic.

Check WAL statistics:

```bash
psql -d ts_ingest_lab -c "SELECT * FROM pg_stat_wal;"
```

This helps understand:

* WAL growth
* Checkpoint pressure
* Disk write impact

---

# PART 10 — Cleanup After Demo

Always return system to clean state.

---

## Step 12: Drop Lab Database

```bash
psql -d postgres -c "DROP DATABASE ts_ingest_lab;"
```

---

## Step 13: Verify Cleanup

```bash
psql -d postgres -c "\l"
```

Ensure `ts_ingest_lab` no longer exists.

---

# Summary

This lab demonstrated:

* Proper hypertable design
* Composite primary key requirement
* 1,000,000 row ingestion
* Automatic chunking
* Chunk exclusion during queries
* Index optimization
* WAL awareness
* Full cleanup process

