**Lesson_05_WAL_Analysis_and_Write_Performance** demo.


* Assumes PostgreSQL 17 + TimescaleDB already installed
* Uses `psql -d db_name -c ""` format everywhere
* Cleans up before starting
* Cleans up after completion
* Includes detailed explanations
* Ready to paste into GitHub `README.md`

---

# Lesson_05_WAL_Analysis_and_Write_Performance

## WAL Behavior and Write Performance Under Heavy Load

PostgreSQL 17 + TimescaleDB Deep Dive Lab

---

## Prerequisites

Before starting:

* PostgreSQL 17 is installed and running
* TimescaleDB is installed and working
* `shared_preload_libraries = 'timescaledb'` is enabled

Verify:

```bash
psql -d postgres -c "SELECT version();"
```

```bash
psql -d postgres -c "SHOW shared_preload_libraries;"
```

Expected:

```
timescaledb
```

---

# PART 1 — Ensure Clean Environment

---

## Step 1: Drop Existing WAL Lab Database

```bash
psql -d postgres -c "DROP DATABASE IF EXISTS wal_lab;"
```

### Explanation

* Prevents leftover objects
* Ensures reproducibility
* Avoids schema conflicts

---

# PART 2 — Create Fresh WAL Lab

---

## Step 2: Create Database

```bash
psql -d postgres -c "CREATE DATABASE wal_lab;"
```

---

## Step 3: Enable TimescaleDB

```bash
psql -d wal_lab -c "CREATE EXTENSION IF NOT EXISTS timescaledb;"
```

---

# PART 3 — Baseline WAL Statistics

Before generating load, measure baseline WAL activity.

---

## Step 4: Check Current WAL Metrics

```bash
psql -d wal_lab -c "SELECT * FROM pg_stat_wal;"
```

### Important Columns

* `wal_records` — number of WAL records generated
* `wal_fpi` — full page images
* `wal_bytes` — total WAL bytes written
* `wal_buffers_full` — WAL buffer flush events

This establishes baseline before workload.

---

# PART 4 — Create Write-Heavy Table

---

## Step 5: Create Schema

```bash
psql -d wal_lab -c "CREATE SCHEMA wal_metrics;"
```

---

## Step 6: Create Table (Partition-Aware Primary Key)

```bash
psql -d wal_lab -c "
CREATE TABLE wal_metrics.events (
    id BIGINT NOT NULL,
    device_id INT NOT NULL,
    event_time TIMESTAMPTZ NOT NULL,
    payload TEXT,
    PRIMARY KEY (id, event_time)
);
"
```

### Why Include event_time in Primary Key?

TimescaleDB requires partition column in any UNIQUE constraint.

---

## Step 7: Convert to Hypertable

```bash
psql -d wal_lab -c "
SELECT create_hypertable(
    'wal_metrics.events',
    'event_time'
);
"
```

---

# PART 5 — Generate High WAL Activity

---

## Step 8: Insert 1,000,000 Rows (High Write Volume)

```bash
psql -d wal_lab -c "
INSERT INTO wal_metrics.events
SELECT generate_series(1,1000000),
       (random()*1000)::int,
       NOW() - (random()*864000 || ' seconds')::interval,
       md5(random()::text);
"
```

### What Happens Internally

* Each insert generates WAL records
* WAL is written before data file modification
* Ensures crash safety
* Timescale distributes rows into chunks

---

# PART 6 — Measure WAL After Heavy Load

---

## Step 9: Check WAL Statistics Again

```bash
psql -d wal_lab -c "SELECT * FROM pg_stat_wal;"
```

Compare with baseline.

You should observe:

* Increased `wal_records`
* Increased `wal_bytes`
* Increased `wal_fpi`

This shows WAL amplification under heavy insert workload.

---

# PART 7 — Measure Checkpoint Activity

---

## Step 10: Check Checkpoint Stats

```bash
psql -d wal_lab -c "SELECT * FROM pg_stat_bgwriter;"
```

Important Fields:

* `checkpoints_timed`
* `checkpoints_req`
* `buffers_checkpoint`
* `buffers_backend`

This indicates disk flush behavior.

---

# PART 8 — Force Manual Checkpoint

---

## Step 11: Run Checkpoint

```bash
psql -d wal_lab -c "CHECKPOINT;"
```

### What This Does

* Flushes dirty buffers to disk
* Reduces recovery time window
* Clears WAL backlog

---

# PART 9 — Measure Query Performance Under Load

---

## Step 12: Run Time-Filtered Query

```bash
psql -d wal_lab -c "
EXPLAIN ANALYZE
SELECT COUNT(*)
FROM wal_metrics.events
WHERE event_time > NOW() - INTERVAL '1 day';
"
```

### What Happens

* Chunk exclusion limits scanned partitions
* Demonstrates Timescale performance advantage

---

# PART 10 — Simulate Batch Inserts

---

## Step 13: Insert Another 500,000 Rows

```bash
psql -d wal_lab -c "
INSERT INTO wal_metrics.events
SELECT generate_series(1000001,1500000),
       (random()*1000)::int,
       NOW(),
       md5(random()::text);
"
```

---

## Step 14: Recheck WAL Stats

```bash
psql -d wal_lab -c "SELECT wal_bytes FROM pg_stat_wal;"
```

This shows cumulative WAL growth.

---

# PART 11 — Compression Impact on WAL (Optional)

Enable compression:

```bash
psql -d wal_lab -c "
ALTER TABLE wal_metrics.events
SET (timescaledb.compress);
"
```

Add compression policy:

```bash
psql -d wal_lab -c "
SELECT add_compression_policy(
    'wal_metrics.events',
    INTERVAL '7 days'
);
"
```

Compression reduces disk footprint and long-term IO cost.

---

# PART 12 — Cleanup Lab

---

## Step 15: Drop Lab Database

```bash
psql -d postgres -c "DROP DATABASE wal_lab;"
```

---

## Step 16: Verify Cleanup

```bash
psql -d postgres -c "\l"
```

Ensure `wal_lab` no longer exists.

---

# Summary

This lab demonstrated:

* WAL generation under high insert load
* WAL byte growth measurement
* Checkpoint behavior
* Background writer activity
* Chunk-based performance with TimescaleDB
* Compression and retention interaction
* Safe cleanup process

---

