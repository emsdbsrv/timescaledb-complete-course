# Lesson 03 -- Creating Time Series Lab Database

## Table of Contents

1.  Introduction
2.  What You Will Do
3.  Prerequisites
4.  Best Practices
5.  Real-World Production Scenario
6.  Complete Step-by-Step Setup
7.  20 Common PostgreSQL Commands
8.  10 Questions and Answers
9.  5 Real-Time Interview Scenarios
10. Summary

------------------------------------------------------------------------

## 1. Introduction

This lesson is fully self-contained.\
You will install PostgreSQL 17, install TimescaleDB, configure
shared_preload_libraries, enable the extension, and build a complete
time-series lab environment from scratch.

------------------------------------------------------------------------

## 2. What You Will Do

• Install PostgreSQL 17 using official PGDG repository\
• Install TimescaleDB extension package\
• Configure shared_preload_libraries properly\
• Restart and validate PostgreSQL configuration\
• Create a dedicated lab database\
• Create schema and hypertable\
• Insert large simulated dataset\
• Validate query performance using execution plans

------------------------------------------------------------------------

## 3. Prerequisites

• Ubuntu 24.04 server\
• Sudo privileges\
• Minimum 4GB RAM recommended\
• Internet connectivity

------------------------------------------------------------------------

## 4. Best Practices

• Never expose port 5432 publicly in production\
• Use SCRAM-SHA-256 authentication\
• Separate lab and production environments\
• Always verify shared_preload_libraries after restart\
• Monitor logs in /var/log/postgresql

------------------------------------------------------------------------

## 5. Real-World Production Scenario

A monitoring platform attempted to enable TimescaleDB but forgot to
configure shared_preload_libraries.\
The extension failed to load background workers.\
After updating postgresql.conf and restarting PostgreSQL, the system
functioned correctly without data corruption.

------------------------------------------------------------------------

## 6. Complete Step-by-Step Setup

### Step 1 -- Install PostgreSQL 17

``` bash
sudo apt update
sudo apt install -y postgresql-common
sudo /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh
sudo apt update
sudo apt install -y postgresql-17 postgresql-client-17 postgresql-contrib-17
sudo systemctl enable postgresql
sudo systemctl start postgresql
```

Validate:

``` bash
sudo -u postgres psql -c "SELECT version();"
```

------------------------------------------------------------------------

### Step 2 -- Install TimescaleDB

``` bash
sudo apt install -y timescaledb-2-postgresql-17
```

------------------------------------------------------------------------

### Step 3 -- Configure shared_preload_libraries

Edit configuration:

``` bash
sudo vi /etc/postgresql/17/main/postgresql.conf
```

Add:

    shared_preload_libraries = 'timescaledb'

Restart:

``` bash
sudo systemctl restart postgresql
```

Validate:

``` bash
sudo -u postgres psql -c "SHOW shared_preload_libraries;"
```

------------------------------------------------------------------------

### Step 4 -- Enable Extension

``` sql
CREATE EXTENSION IF NOT EXISTS timescaledb;
\dx
```

------------------------------------------------------------------------

### Step 5 -- Create Lab Database

``` sql
CREATE DATABASE ts_lab;
\c ts_lab
```

------------------------------------------------------------------------

### Step 6 -- Create Schema

``` sql
CREATE SCHEMA metrics;
```

------------------------------------------------------------------------

### Step 7 -- Create Time-Series Table

``` sql
CREATE TABLE metrics.sensor_data (
    id BIGSERIAL PRIMARY KEY,
    device_id INT NOT NULL,
    recorded_at TIMESTAMPTZ NOT NULL,
    temperature DOUBLE PRECISION,
    humidity DOUBLE PRECISION
);
```

------------------------------------------------------------------------

### Step 8 -- Convert to Hypertable

``` sql
SELECT create_hypertable('metrics.sensor_data', 'recorded_at');
```

------------------------------------------------------------------------

### Step 9 -- Create Index

``` sql
CREATE INDEX idx_sensor_time
ON metrics.sensor_data(recorded_at DESC);
```

------------------------------------------------------------------------

### Step 10 -- Insert Sample Data

``` sql
INSERT INTO metrics.sensor_data
SELECT
    generate_series(1, 100000),
    (random()*10)::int,
    NOW() - (random()*1000 || ' seconds')::interval,
    random()*50,
    random()*100;
```

------------------------------------------------------------------------

### Step 11 -- Performance Validation

``` sql
SELECT COUNT(*) FROM metrics.sensor_data;

EXPLAIN ANALYZE
SELECT *
FROM metrics.sensor_data
WHERE recorded_at > NOW() - INTERVAL '1 hour';
```

------------------------------------------------------------------------

## 7. 20 Common PostgreSQL Commands

`\l  `{=tex} `\du  `{=tex} `\dt  `{=tex} `\dn  `{=tex} `\dx  `{=tex}
SELECT version();\
SHOW data_directory;\
SHOW config_file;\
SHOW shared_preload_libraries;\
SELECT pg_reload_conf();\
SELECT now();\
CREATE DATABASE demo;\
DROP DATABASE demo;\
CREATE ROLE dev LOGIN PASSWORD 'x';\
GRANT ALL ON DATABASE ts_lab TO dev;\
REVOKE ALL ON DATABASE ts_lab FROM dev;\
VACUUM ANALYZE;\
REINDEX TABLE metrics.sensor_data;\
SELECT \* FROM pg_stat_activity;\
DROP SCHEMA metrics CASCADE;

------------------------------------------------------------------------

## 8. 10 Questions and Answers

1.  Why configure shared_preload_libraries? → Required to load
    TimescaleDB background workers.\
2.  Why restart PostgreSQL after editing config? → Preload libraries
    require restart.\
3.  What is hypertable? → Logical abstraction over partitioned chunks.\
4.  Why index recorded_at? → Improve time-based filtering.\
5.  How to validate extension installed? → Use `\dx `{=tex}command.

------------------------------------------------------------------------

## 9. 5 Real-Time Interview Scenarios

1.  Extension fails to load → shared_preload_libraries missing.\
2.  Slow inserts → WAL or checkpoint tuning required.\
3.  Sequential scan → Missing index.\
4.  High disk usage → Compression not configured.\
5.  Connection refused → Firewall or listen_addresses misconfigured.

------------------------------------------------------------------------

## 10. Summary

You installed PostgreSQL.\
You installed TimescaleDB.\
You configured shared_preload_libraries correctly.\
You created a hypertable-based lab database.\
You inserted high-volume dataset.\
You validated query performance successfully.
