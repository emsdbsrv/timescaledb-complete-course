# Lesson_03_Creating_Time_Series_Lab_DB
## Complete Practical Assignment – Aligned with Demo v2

This assignment requires full PostgreSQL 17 validation,
passwordless sudo configuration, TimescaleDB setup,
hypertable creation, 1,000,000 row ingestion,
compression, retention, continuous aggregates, and cleanup.

------------------------------------------------------------
PART 1 – PostgreSQL Validation
------------------------------------------------------------

SELECT version();
\l
\du

------------------------------------------------------------
PART 2 – Verify shared_preload_libraries
------------------------------------------------------------

SHOW shared_preload_libraries;

------------------------------------------------------------
PART 3 – Database & Extension Setup
------------------------------------------------------------

CREATE DATABASE ts_lab;
\c ts_lab
CREATE EXTENSION IF NOT EXISTS timescaledb;
\dx

------------------------------------------------------------
PART 4 – Schema & Table Creation
------------------------------------------------------------

CREATE SCHEMA metrics;

CREATE TABLE metrics.sensor_data (
    id BIGSERIAL PRIMARY KEY,
    device_id INT NOT NULL,
    recorded_at TIMESTAMPTZ NOT NULL,
    temperature DOUBLE PRECISION,
    humidity DOUBLE PRECISION
);

------------------------------------------------------------
PART 5 – Hypertable Conversion
------------------------------------------------------------

SELECT create_hypertable(
    'metrics.sensor_data',
    'recorded_at',
    chunk_time_interval => INTERVAL '1 day'
);

------------------------------------------------------------
PART 6 – Insert 1,000,000 Rows
------------------------------------------------------------

INSERT INTO metrics.sensor_data
SELECT
    generate_series(1,1000000),
    (random()*100)::int,
    NOW() - (random()*200000 || ' seconds')::interval,
    random()*50,
    random()*100;

------------------------------------------------------------
PART 7 – Performance & Indexing
------------------------------------------------------------

CREATE INDEX idx_recorded_at_desc
ON metrics.sensor_data (recorded_at DESC);

SELECT COUNT(*) FROM metrics.sensor_data;

EXPLAIN ANALYZE
SELECT *
FROM metrics.sensor_data
WHERE recorded_at > NOW() - INTERVAL '1 hour';

------------------------------------------------------------
PART 8 – Compression
------------------------------------------------------------

ALTER TABLE metrics.sensor_data
SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'device_id'
);

SELECT add_compression_policy(
    'metrics.sensor_data',
    INTERVAL '7 days'
);

------------------------------------------------------------
PART 9 – Retention & Aggregation
------------------------------------------------------------

SELECT add_retention_policy(
    'metrics.sensor_data',
    INTERVAL '30 days'
);

CREATE MATERIALIZED VIEW metrics.hourly_avg
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 hour', recorded_at) AS bucket,
    device_id,
    avg(temperature) AS avg_temp
FROM metrics.sensor_data
GROUP BY bucket, device_id;

------------------------------------------------------------
PART 10 – Cleanup
------------------------------------------------------------

DROP MATERIALIZED VIEW metrics.hourly_avg;
DROP TABLE metrics.sensor_data;
DROP SCHEMA metrics CASCADE;
\c postgres
DROP DATABASE ts_lab;

------------------------------------------------------------
Submission Requirements
------------------------------------------------------------

• PostgreSQL version output
• shared_preload_libraries output
• \dx confirmation
• 1,000,000 row confirmation
• EXPLAIN ANALYZE output
• Compression policy confirmation
• Retention confirmation
• Cleanup confirmation
