# Lesson_03_Creating_Time_Series_Lab_DB

## Complete End-to-End PostgreSQL 17 + TimescaleDB Setup

Full Installation, Configuration, Time-Series Lab, and Cleanup

This guide walks through:

* PostgreSQL 17 installation
* Secure configuration
* Remote access setup (`0.0.0.0/0`)
* Passwordless sudo configuration
* TimescaleDB installation
* Hypertable creation
* 1,000,000 row ingestion
* Performance validation
* Advanced Timescale features
* Full cleanup

All steps are written for Ubuntu 24.04 and must be executed using a sudo-privileged user.

---

# PART 1 — Install PostgreSQL 17

## Step 1: Install `postgresql-common` and Configure Official Repository

```bash
sudo apt update
sudo apt install -y postgresql-common
sudo /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh
sudo apt update
```

### What This Does

* Updates system package index.
* Installs `postgresql-common` which manages PostgreSQL versions.
* Adds the official PostgreSQL Global Development Group (PGDG) repository.
* Makes PostgreSQL 17 available for installation.

---

## Step 2: Install PostgreSQL 17 Server and Tools

```bash
sudo apt install -y postgresql-17 postgresql-client-17 postgresql-contrib-17
```

### What This Does

* Installs PostgreSQL 17 database engine.
* Installs `psql` client.
* Installs contrib extensions such as `pg_stat_statements`.

---

## Step 3: Enable and Start PostgreSQL

```bash
sudo systemctl enable postgresql
sudo systemctl start postgresql
```

### What This Does

* Ensures PostgreSQL starts automatically on reboot.
* Starts PostgreSQL immediately.

---

## Step 4: Secure `postgres` Superuser

```bash
sudo -i -u postgres
psql -c "ALTER USER postgres WITH PASSWORD 'password#123456';"
exit
```

### What This Does

* Switches to PostgreSQL OS user.
* Sets password for database superuser.
* Enables secure remote authentication.

---

## Step 5: Grant Passwordless sudo to `postgres` OS User

```bash
sudo cp /etc/sudoers /etc/sudoers.bak
echo "postgres ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers > /dev/null
```

### What This Does

* Creates backup of sudoers file.
* Allows `postgres` OS user to execute administrative commands without password.
* Useful for automation and backup scripts.

---

# PART 2 — Enable Remote Access (0.0.0.0/0)

⚠ For lab use only. Restrict in production.

---

## Step 6: Allow PostgreSQL to Listen on All Interfaces

```bash
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" \
/etc/postgresql/17/main/postgresql.conf
```

### Definition

`listen_addresses` controls which network interfaces PostgreSQL listens on.

`'*'` allows all interfaces.

---

## Step 7: Allow All IPv4 Connections

```bash
echo "host all all 0.0.0.0/0 scram-sha-256" | \
sudo tee -a /etc/postgresql/17/main/pg_hba.conf
```

### Definition

`pg_hba.conf` defines client authentication rules.

* `0.0.0.0/0` = all IPv4 addresses
* `scram-sha-256` = secure password hashing

---

## Step 8: Restart PostgreSQL

```bash
sudo systemctl restart postgresql
```

---

## Step 9: Open Port 5432

```bash
sudo ufw allow 5432/tcp
```

If using AWS Security Group:

| Setting  | Value      |
| -------- | ---------- |
| Type     | PostgreSQL |
| Protocol | TCP        |
| Port     | 5432       |
| Source   | 0.0.0.0/0  |

---

## Step 10: Validate Installation

```bash
sudo systemctl status postgresql
ss -tln | grep 5432
sudo -u postgres psql -c "SELECT version();"
sudo -u postgres psql -c "\l" -c "\du"
```

---

# PART 3 — Install TimescaleDB

TimescaleDB is a PostgreSQL extension optimized for time-series workloads.
It automatically partitions data into chunks for high-performance querying.

---

## Step 11: Add TimescaleDB Repository and Install

```bash
sudo sh -c "echo 'deb https://packagecloud.io/timescale/timescaledb/ubuntu/ jammy main' > /etc/apt/sources.list.d/timescaledb.list"

wget --quiet -O - https://packagecloud.io/timescale/timescaledb/gpgkey | sudo apt-key add -

sudo apt update
sudo apt install -y timescaledb-2-postgresql-17
```

---

## Step 12: Enable `shared_preload_libraries`

```bash
sudo sed -i "s/#shared_preload_libraries = ''/shared_preload_libraries = 'timescaledb'/g" \
/etc/postgresql/17/main/postgresql.conf
```

### Definition

`shared_preload_libraries` loads background workers required for:

* Chunk management
* Compression
* Continuous aggregates

---

## Step 13: Restart PostgreSQL

```bash
sudo systemctl restart postgresql
```

---

## Step 14: Validate TimescaleDB Loaded

```bash
sudo -u postgres psql -c "SHOW shared_preload_libraries;"
```

Expected output:

```
timescaledb
```

---

# PART 4 — Create Time-Series Lab

---

## Step 15: Create Database and Enable Extension

```bash
sudo -u postgres psql
```

```sql
CREATE DATABASE ts_lab;
\c ts_lab
CREATE EXTENSION timescaledb;
```

---

## Step 16: Create Schema and Table (Correct Hypertable Design)

```sql
CREATE SCHEMA metrics;

CREATE TABLE metrics.sensor_data (
    id BIGINT NOT NULL,
    device_id INT NOT NULL,
    recorded_at TIMESTAMPTZ NOT NULL,
    temperature DOUBLE PRECISION,
    humidity DOUBLE PRECISION,
    PRIMARY KEY (id, recorded_at)
);
```

### Why Composite Primary Key?

TimescaleDB requires that the partitioning column (`recorded_at`)
must be part of any UNIQUE constraint.

This ensures uniqueness across chunks.

---

## Step 17: Convert to Hypertable

```sql
SELECT create_hypertable('metrics.sensor_data','recorded_at');
```

### Definition

A hypertable is a logical table that automatically partitions data
into smaller physical tables called chunks based on time.

---

## Step 18: Insert 1,000,000 Rows

```sql
INSERT INTO metrics.sensor_data
SELECT generate_series(1,1000000),
       (random()*100)::int,
       NOW() - (random()*200000 || ' seconds')::interval,
       random()*50,
       random()*100;
```

### What This Simulates

* High-ingestion IoT workload
* Automatic chunk creation
* Time-based partitioning

---

## Step 19: Validate Performance

```sql
SELECT COUNT(*) FROM metrics.sensor_data;

EXPLAIN ANALYZE
SELECT *
FROM metrics.sensor_data
WHERE recorded_at > NOW() - INTERVAL '1 hour';
```

### Definition

`EXPLAIN ANALYZE` shows execution plan and runtime.
Timescale performs chunk exclusion to scan only relevant partitions.

---

# PART 5 — Advanced Timescale Features

---

## Enable Compression

```sql
ALTER TABLE metrics.sensor_data
SET (timescaledb.compress, timescaledb.compress_segmentby='device_id');

SELECT add_compression_policy('metrics.sensor_data', INTERVAL '7 days');
```

### Definition

Compression reduces storage footprint and improves analytical performance.

---

## Add Retention Policy

```sql
SELECT add_retention_policy('metrics.sensor_data', INTERVAL '30 days');
```

### Definition

Automatically drops old chunks to control data growth.

---

## Create Continuous Aggregate

```sql
CREATE MATERIALIZED VIEW metrics.hourly_avg
WITH (timescaledb.continuous) AS
SELECT time_bucket('1 hour', recorded_at) AS bucket,
       device_id,
       avg(temperature)
FROM metrics.sensor_data
GROUP BY bucket, device_id;
```

### Definition

Continuous aggregates automatically refresh summarized time-bucketed data.

---

# PART 6 — Cleanup Lab

```sql
DROP MATERIALIZED VIEW metrics.hourly_avg;
DROP TABLE metrics.sensor_data;
DROP SCHEMA metrics CASCADE;
\c postgres
DROP DATABASE ts_lab;
```

---

# Environment Summary

This lab includes:

* PostgreSQL 17 installation
* Secure configuration
* Passwordless sudo configuration
* Remote access configuration (`0.0.0.0/0`)
* TimescaleDB installation
* Hypertable with 1M rows
* Compression
* Retention policy
* Continuous aggregates
* Full cleanup

---


