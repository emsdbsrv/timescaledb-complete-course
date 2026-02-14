
# Lesson_06_Chunk_Management_and_Query_Optimization

## Complete Assignment

TimescaleDB Chunk Management, Query Optimization, Compression, Retention, and Cleanup

---

## Objective

In this assignment you will:

* Create a hypertable with custom chunk interval
* Insert 1,500,000 rows
* Analyze chunk distribution
* Optimize queries using indexes
* Enable compression
* Add retention policy
* Validate performance
* Perform full cleanup

Environment assumption:

* PostgreSQL 17 is installed and running
* TimescaleDB is installed and working
* Extension loads successfully

---

# PART 1 — Ensure Clean Environment

---

## Step 1: Drop Old Assignment Database (If Exists)

```bash
psql -d postgres -c "DROP DATABASE IF EXISTS assignment_chunk_lab;"
```

### What this does:

* Prevents schema conflicts
* Guarantees fresh starting point

---

## Step 2: Create New Assignment Database

```bash
psql -d postgres -c "CREATE DATABASE assignment_chunk_lab;"
```

---

## Step 3: Enable TimescaleDB Extension

```bash
psql -d assignment_chunk_lab -c "CREATE EXTENSION IF NOT EXISTS timescaledb;"
```

This enables hypertable functionality.

---

# PART 2 — Create Hypertable with 12-Hour Chunk Interval

---

## Step 4: Create Schema

```bash
psql -d assignment_chunk_lab -c "CREATE SCHEMA telemetry;"
```

---

## Step 5: Create Base Table

```bash
psql -d assignment_chunk_lab -c "
CREATE TABLE telemetry.iot_readings (
    id BIGINT NOT NULL,
    device_id INT NOT NULL,
    recorded_at TIMESTAMPTZ NOT NULL,
    pressure DOUBLE PRECISION,
    voltage DOUBLE PRECISION,
    PRIMARY KEY (id, recorded_at)
);"
```

### Why include recorded_at in primary key?

Timescale requires the partitioning column
to be part of the primary key or unique constraint.

---

## Step 6: Convert to Hypertable

```bash
psql -d assignment_chunk_lab -c "
SELECT create_hypertable(
    'telemetry.iot_readings',
    'recorded_at',
    chunk_time_interval => INTERVAL '12 hours'
);"
```

### What this does:

* Enables automatic time-based partitioning
* Each chunk stores 12 hours of data
* Improves query and insert performance

---

# PART 3 — Insert 1,500,000 Rows

---

## Step 7: Insert Massive Dataset

```bash
psql -d assignment_chunk_lab -c "
INSERT INTO telemetry.iot_readings
SELECT
    generate_series(1,1500000),
    (random()*500)::int,
    NOW() - (random()*1209600 || ' seconds')::interval,
    random()*200,
    random()*5;
"
```

### What this simulates:

* 1.5 million telemetry events
* Distributed across ~14 days
* Multiple chunks automatically created

---

## Step 8: Verify Row Count

```bash
psql -d assignment_chunk_lab -c "
SELECT COUNT(*) FROM telemetry.iot_readings;
"
```

Expected result: 1500000

---

# PART 4 — Analyze Chunk Distribution

---

## Step 9: View Chunk Metadata

```bash
psql -d assignment_chunk_lab -c "
SELECT chunk_name, range_start, range_end
FROM timescaledb_information.chunks
WHERE hypertable_name = 'iot_readings';
"
```

### Observe:

* Number of chunks created
* Time boundaries
* Confirm 12-hour segmentation

---

# PART 5 — Query Optimization

---

## Step 10: Run Time-Filtered Query

```bash
psql -d assignment_chunk_lab -c "
EXPLAIN ANALYZE
SELECT *
FROM telemetry.iot_readings
WHERE recorded_at > NOW() - INTERVAL '2 hours';
"
```

### What to observe:

* Chunk exclusion in execution plan
* Only recent chunk scanned
* Reduced execution time

---

## Step 11: Create Composite Index

```bash
psql -d assignment_chunk_lab -c "
CREATE INDEX idx_device_time
ON telemetry.iot_readings(device_id, recorded_at DESC);
"
```

### Why?

* Speeds up device-specific recent queries
* Improves filtering efficiency

---

## Step 12: Re-test Performance

```bash
psql -d assignment_chunk_lab -c "
EXPLAIN ANALYZE
SELECT *
FROM telemetry.iot_readings
WHERE device_id = 42
AND recorded_at > NOW() - INTERVAL '1 day';
"
```

Compare execution time before and after index creation.

---

# PART 6 — Enable Compression

---

## Step 13: Activate Compression

```bash
psql -d assignment_chunk_lab -c "
ALTER TABLE telemetry.iot_readings
SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'device_id'
);
"
```

Compression reduces disk usage for historical chunks.

---

## Step 14: Add Compression Policy

```bash
psql -d assignment_chunk_lab -c "
SELECT add_compression_policy(
    'telemetry.iot_readings',
    INTERVAL '3 days'
);
"
```

Chunks older than 3 days will be compressed automatically.

---

# PART 7 — Add Retention Policy

---

## Step 15: Add Retention Rule

```bash
psql -d assignment_chunk_lab -c "
SELECT add_retention_policy(
    'telemetry.iot_readings',
    INTERVAL '60 days'
);
"
```

This ensures long-term storage remains controlled.

---

# PART 8 — Validate Storage Size

---

## Step 16: Check Table Size

```bash
psql -d assignment_chunk_lab -c "
SELECT pg_size_pretty(
    pg_total_relation_size('telemetry.iot_readings')
);
"
```

Observe storage footprint.

---

# PART 9 — Final Cleanup

---

## Step 17: Remove Policies

```bash
psql -d assignment_chunk_lab -c "
SELECT remove_compression_policy('telemetry.iot_readings');
SELECT remove_retention_policy('telemetry.iot_readings');
"
```

---

## Step 18: Drop Database

```bash
psql -d postgres -c "DROP DATABASE assignment_chunk_lab;"
```

Environment is now fully cleaned.

---

# Deliverables Checklist

You should be able to:

* Explain chunk_time_interval
* Demonstrate chunk exclusion
* Compare indexed vs non-indexed query
* Explain compression mechanics
* Explain retention lifecycle
* Clean environment safely

---

