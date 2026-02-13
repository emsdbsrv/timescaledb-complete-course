# Lesson 03 -- Creating Time Series Lab Database Assignment

## Objective

Build a complete PostgreSQL + TimescaleDB time-series environment from
scratch and validate performance.

------------------------------------------------------------------------

## Step 1 -- Install PostgreSQL

``` bash
sudo apt update
sudo apt install -y postgresql-17
sudo systemctl start postgresql
```

------------------------------------------------------------------------

## Step 2 -- Install TimescaleDB

``` bash
sudo apt install -y timescaledb-2-postgresql-17
```

Edit postgresql.conf and add:

    shared_preload_libraries = 'timescaledb'

Restart:

``` bash
sudo systemctl restart postgresql
```

------------------------------------------------------------------------

## Step 3 -- Database Setup

``` sql
CREATE DATABASE analytics_lab;
\c analytics_lab;

CREATE EXTENSION timescaledb;

CREATE SCHEMA telemetry;

CREATE TABLE telemetry.cpu_metrics (
    id BIGSERIAL PRIMARY KEY,
    host_name TEXT NOT NULL,
    recorded_at TIMESTAMPTZ NOT NULL,
    cpu_usage DOUBLE PRECISION NOT NULL
);
```

------------------------------------------------------------------------

## Step 4 -- Convert to Hypertable

``` sql
SELECT create_hypertable('telemetry.cpu_metrics','recorded_at');
```

------------------------------------------------------------------------

## Step 5 -- Insert 500,000 Rows

``` sql
INSERT INTO telemetry.cpu_metrics
SELECT
    generate_series(1,500000),
    'server_' || (random()*10)::int,
    NOW() - (random()*10000 || ' seconds')::interval,
    random()*100;
```

------------------------------------------------------------------------

## Step 6 -- Index Optimization

``` sql
CREATE INDEX idx_cpu_time
ON telemetry.cpu_metrics(recorded_at DESC);
```

------------------------------------------------------------------------

## Step 7 -- Performance Testing

``` sql
EXPLAIN ANALYZE
SELECT *
FROM telemetry.cpu_metrics
WHERE recorded_at > NOW() - INTERVAL '2 hours';
```

------------------------------------------------------------------------

## Deliverables

• Screenshot of SHOW shared_preload_libraries\
• Screenshot of `\dx `{=tex}showing timescaledb\
• Execution plan output\
• Row count verification\
• SQL script used for full setup
