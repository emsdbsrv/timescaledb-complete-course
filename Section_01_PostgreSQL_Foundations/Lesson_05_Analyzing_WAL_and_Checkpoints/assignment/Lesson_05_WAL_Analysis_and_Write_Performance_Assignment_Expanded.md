
# Lesson_05_WAL_Analysis_and_Write_Performance_Assignment

## Objective
Analyze WAL growth under heavy insert load and tune PostgreSQL accordingly.

## Step 1: Create Database
psql -d postgres -c "CREATE DATABASE wal_assignment;"

## Step 2: Enable TimescaleDB
psql -d wal_assignment -c "CREATE EXTENSION IF NOT EXISTS timescaledb;"

## Step 3: Create Schema and Hypertable
psql -d wal_assignment -c "CREATE SCHEMA wal_metrics;"

psql -d wal_assignment -c "
CREATE TABLE wal_metrics.logs (
    id BIGINT NOT NULL,
    device_id INT NOT NULL,
    event_time TIMESTAMPTZ NOT NULL,
    payload TEXT,
    PRIMARY KEY (id, event_time)
);"

psql -d wal_assignment -c "
SELECT create_hypertable('wal_metrics.logs','event_time');"

## Step 4: Record Initial WAL Stats
psql -d wal_assignment -c "SELECT wal_bytes FROM pg_stat_wal;"

## Step 5: Insert 1,000,000 Rows
psql -d wal_assignment -c "
INSERT INTO wal_metrics.logs
SELECT generate_series(1,1000000),
       (random()*1000)::int,
       NOW() - (random()*864000 || ' seconds')::interval,
       md5(random()::text);"

## Step 6: Measure WAL Growth
psql -d wal_assignment -c "SELECT wal_bytes FROM pg_stat_wal;"

## Step 7: Force Checkpoint
psql -d wal_assignment -c "CHECKPOINT;"

## Step 8: Performance Query
psql -d wal_assignment -c "
EXPLAIN ANALYZE
SELECT COUNT(*)
FROM wal_metrics.logs
WHERE event_time > NOW() - INTERVAL '1 day';"

## Step 9: Cleanup
psql -d postgres -c "DROP DATABASE wal_assignment;"
