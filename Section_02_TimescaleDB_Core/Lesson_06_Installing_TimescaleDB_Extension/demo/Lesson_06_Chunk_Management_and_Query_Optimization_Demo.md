# Lesson_06_Chunk_Management_and_Query_Optimization

## Complete End-to-End Demo

TimescaleDB Chunk Management, Query Optimization, and Cleanup

---

## Prerequisite

* PostgreSQL 17 is installed and running
* TimescaleDB is installed and loaded (`shared_preload_libraries = 'timescaledb'`)
* Extension works (`CREATE EXTENSION timescaledb;` works without error)

We assume environment is ready.

This lab will:

* Clean previous data
* Create new hypertable
* Insert 1,000,000 rows
* Analyze chunk behavior
* Optimize queries
* Enable compression
* Add retention
* Perform final cleanup

---

# PART 1 — Clean Environment Before Starting

---

## Step 1: Drop Old Database (If Exists)

```bash
psql -d postgres -c "DROP DATABASE IF EXISTS chunk_lab;"
```

### What this does:

* Ensures no leftover lab database exists
* Prevents schema conflicts
* Guarantees clean starting state

---

## Step 2: Create Fresh Lab Database

```bash
psql -d postgres -c "CREATE DATABASE chunk_lab;"
```

### What this does:

* Creates isolated testing environment
* Keeps production databases unaffected

---

## Step 3: Enable TimescaleDB Extension

```bash
psql -d chunk_lab -c "CREATE EXTENSION IF NOT EXISTS timescaledb;"
```

### What this does:

* Activates TimescaleDB features
* Enables hypertables
* Enables chunking engine

TimescaleDB converts normal PostgreSQL tables into **hypertables**, which are automatically partitioned by time.

---

# PART 2 — Create Hypertable with Custom Chunk Interval

---

## Step 4: Create Schema

```bash
psql -d chunk_lab -c "CREATE SCHEMA metrics;"
```

### What this does:

* Organizes time-series tables
* Keeps lab structured

---

## Step 5: Create Base Table

```bash
psql -d chunk_lab -c "
CREATE TABLE metrics.device_metrics (
    id BIGINT NOT NULL,
    device_id INT NOT NULL,
    recorded_at TIMESTAMPTZ NOT NULL,
    temperature DOUBLE PRECISION,
    humidity DOUBLE PRECISION,
    PRIMARY KEY (id, recorded_at)
);"
```

### Why composite primary key?

Timescale requires that:

> Partitioning column must be part of the primary key.

Since we partition by `recorded_at`, it must be included in the key.

---

## Step 6: Convert Table to Hypertable

```bash
psql -d chunk_lab -c "
SELECT create_hypertable(
    'metrics.device_metrics',
    'recorded_at',
    chunk_time_interval => INTERVAL '1 day'
);"
```

### What this does:

* Converts table into hypertable
* Automatically creates time-based partitions (chunks)
* Each chunk will hold 1 day of data

Chunks improve:

* Insert performance
* Query speed
* Data lifecycle management

---

# PART 3 — Insert 1,000,000 Rows

---

## Step 7: Insert Massive Dataset

```bash
psql -d chunk_lab -c "
INSERT INTO metrics.device_metrics
SELECT
    generate_series(1,1000000),
    (random()*1000)::int,
    NOW() - (random()*864000 || ' seconds')::interval,
    random()*50,
    random()*100;
"
```

### What this does:

* Inserts 1 million rows
* Simulates IoT sensor workload
* Distributes timestamps randomly across past 10 days
* Automatically creates multiple chunks

TimescaleDB automatically routes rows into appropriate chunk.

---

# PART 4 — Inspect Chunk Behavior

---

## Step 8: View Created Chunks

```bash
psql -d chunk_lab -c "
SELECT chunk_name, range_start, range_end
FROM timescaledb_information.chunks
WHERE hypertable_name = 'device_metrics';
"
```

### What this does:

* Displays chunk boundaries
* Shows time ranges per chunk
* Confirms automatic partitioning

---

## Step 9: Count Total Rows

```bash
psql -d chunk_lab -c "
SELECT COUNT(*) FROM metrics.device_metrics;
"
```

Confirms 1,000,000 rows inserted.

---

# PART 5 — Query Optimization

---

## Step 10: Run Time-Filtered Query

```bash
psql -d chunk_lab -c "
EXPLAIN ANALYZE
SELECT *
FROM metrics.device_metrics
WHERE recorded_at > NOW() - INTERVAL '1 hour';
"
```

### What this does:

* Uses chunk exclusion
* Only scans recent chunk
* Avoids scanning full table

Chunk exclusion dramatically improves performance.

---

## Step 11: Create Index for Recent Queries

```bash
psql -d chunk_lab -c "
CREATE INDEX idx_device_time
ON metrics.device_metrics(device_id, recorded_at DESC);
"
```

### Why?

* Optimizes device-specific recent queries
* Improves planner efficiency

---

# PART 6 — Advanced Timescale Features

---

## Step 12: Enable Compression

```bash
psql -d chunk_lab -c "
ALTER TABLE metrics.device_metrics
SET (timescaledb.compress,
     timescaledb.compress_segmentby = 'device_id');
"
```

### What this does:

* Enables columnar compression
* Compresses old chunks
* Reduces disk usage

---

## Step 13: Add Compression Policy

```bash
psql -d chunk_lab -c "
SELECT add_compression_policy(
    'metrics.device_metrics',
    INTERVAL '7 days'
);
"
```

Old chunks (older than 7 days) get compressed automatically.

---

## Step 14: Add Retention Policy

```bash
psql -d chunk_lab -c "
SELECT add_retention_policy(
    'metrics.device_metrics',
    INTERVAL '30 days'
);
"
```

Automatically deletes chunks older than 30 days.

Prevents unlimited storage growth.

---

# PART 7 — Validate Optimization

---

## Step 15: Check Table Size

```bash
psql -d chunk_lab -c "
SELECT pg_size_pretty(
    pg_total_relation_size('metrics.device_metrics')
);
"
```

Shows actual disk usage.

---

# PART 8 — Final Cleanup

---

## Step 16: Remove Policies

```bash
psql -d chunk_lab -c "
SELECT remove_compression_policy('metrics.device_metrics');
SELECT remove_retention_policy('metrics.device_metrics');
"
```

---

## Step 17: Drop Database Completely

```bash
psql -d postgres -c "DROP DATABASE chunk_lab;"
```

Environment is now fully cleaned.

---

# What This Lesson Demonstrated

* Hypertable creation
* Chunk internals
* 1 million row ingestion
* Chunk exclusion
* Index optimization
* Compression policy
* Retention policy
* Full lifecycle management
* Complete cleanup

---

