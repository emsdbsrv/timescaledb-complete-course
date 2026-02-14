# Lesson_07_Creating_Hypertables

## Complete Step-by-Step Demo

Hypertable Creation, 1M Row Ingestion, Chunk Validation, Optimization, and Cleanup

---

## Prerequisite

* PostgreSQL 17 installed and running
* TimescaleDB installed and working
* `shared_preload_libraries = 'timescaledb'`
* Extension loads successfully

This lab demonstrates:

* Clean environment setup
* Proper hypertable creation
* Correct primary key structure
* 1,000,000 row ingestion
* Chunk validation
* Query optimization
* Full cleanup

---

# PART 1 — Clean Environment Before Starting

---

## Step 1: Drop Old Lab Database (If Exists)

```bash
psql -d postgres -c "DROP DATABASE IF EXISTS hypertable_lab;"
```

### What this does

Removes any previous lab environment.
Prevents naming conflicts.
Ensures clean starting state.

---

## Step 2: Create Fresh Lab Database

```bash
psql -d postgres -c "CREATE DATABASE hypertable_lab;"
```

---

## Step 3: Enable TimescaleDB Extension

```bash
psql -d hypertable_lab -c "CREATE EXTENSION IF NOT EXISTS timescaledb;"
```

### What this does

Activates TimescaleDB capabilities.
Enables hypertables and chunking engine.

---

# PART 2 — Create Base Table Correctly

---

## Step 4: Create Schema

```bash
psql -d hypertable_lab -c "CREATE SCHEMA telemetry;"
```

Organizes objects cleanly.

---

## Step 5: Create Regular PostgreSQL Table

```bash
psql -d hypertable_lab -c "
CREATE TABLE telemetry.device_readings (
    id BIGINT NOT NULL,
    device_id INT NOT NULL,
    recorded_at TIMESTAMPTZ NOT NULL,
    temperature DOUBLE PRECISION,
    humidity DOUBLE PRECISION,
    PRIMARY KEY (id, recorded_at)
);"
```

### Why include recorded_at in PRIMARY KEY?

TimescaleDB requires the partitioning column
to be part of the primary or unique key.

This prevents the error:

> cannot create a unique index without the partitioning column

Composite primary keys ensure uniqueness across chunks.

---

# PART 3 — Convert to Hypertable

---

## Step 6: Create Hypertable

```bash
psql -d hypertable_lab -c "
SELECT create_hypertable(
    'telemetry.device_readings',
    'recorded_at',
    chunk_time_interval => INTERVAL '1 day'
);"
```

### What this does

Transforms table into hypertable.
Registers table with Timescale metadata.
Creates internal time-based partitions (chunks).
Future inserts are automatically routed.

Chunk interval is set to 1 day.

---

# PART 4 — Insert 1,000,000 Rows

---

## Step 7: Insert Large Dataset

```bash
psql -d hypertable_lab -c "
INSERT INTO telemetry.device_readings
SELECT
    generate_series(1,1000000),
    (random()*500)::int,
    NOW() - (random()*864000 || ' seconds')::interval,
    random()*50,
    random()*100;
"
```

### What this simulates

High-ingestion IoT workload.
Random timestamps distributed over ~10 days.
Automatic chunk creation across time intervals.
Demonstrates TimescaleDB write scalability.

---

## Step 8: Validate Row Count

```bash
psql -d hypertable_lab -c "
SELECT COUNT(*) FROM telemetry.device_readings;
"
```

Expected result: 1000000

---

# PART 5 — Inspect Chunk Creation

---

## Step 9: View Internal Chunks

```bash
psql -d hypertable_lab -c "
SELECT chunk_name, range_start, range_end
FROM timescaledb_information.chunks
WHERE hypertable_name = 'device_readings';
"
```

### What this shows

Each physical chunk table.
Time range boundaries per chunk.
Confirms automatic time-based partitioning.

You should see multiple chunks representing 1-day intervals.

---

# PART 6 — Query Optimization

---

## Step 10: Run Time-Filtered Query

```bash
psql -d hypertable_lab -c "
EXPLAIN ANALYZE
SELECT *
FROM telemetry.device_readings
WHERE recorded_at > NOW() - INTERVAL '1 hour';
"
```

### What to observe

Chunk exclusion in execution plan.
Only relevant recent chunk scanned.
Reduced IO and faster execution.

This is the key performance benefit of hypertables.

---

## Step 11: Create Composite Index

```bash
psql -d hypertable_lab -c "
CREATE INDEX idx_device_time
ON telemetry.device_readings(device_id, recorded_at DESC);
"
```

Improves device-specific recent queries.
Enhances planner efficiency.

---

## Step 12: Re-test Optimized Query

```bash
psql -d hypertable_lab -c "
EXPLAIN ANALYZE
SELECT *
FROM telemetry.device_readings
WHERE device_id = 42
AND recorded_at > NOW() - INTERVAL '6 hours';
"
```

Observe index scan usage.
Execution time should decrease.

---

# PART 7 — Storage Validation

---

## Step 13: Check Table Size

```bash
psql -d hypertable_lab -c "
SELECT pg_size_pretty(
    pg_total_relation_size('telemetry.device_readings')
);
"
```

Shows total disk usage including indexes.

Important for production capacity planning.

---

# PART 8 — Final Cleanup

---

## Step 14: Drop Database

```bash
psql -d postgres -c "DROP DATABASE hypertable_lab;"
```

Environment is fully cleaned.

---

# What This Lesson Demonstrated

* Correct hypertable creation
* Proper composite primary key requirement
* Automatic chunk generation
* 1,000,000 row ingestion
* Chunk metadata inspection
* Query optimization using chunk exclusion
* Index optimization strategy
* Safe full cleanup

---
