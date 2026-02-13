
# Lesson_03_Creating_Time_Series_Lab_DB
## Complete End-to-End Step-by-Step Setup
PostgreSQL 17 + TimescaleDB Full Installation, Configuration, Lab, and Cleanup

This guide provides a complete workflow from repository configuration
through PostgreSQL 17 installation, remote access configuration (0.0.0.0/0),
sudo configuration, TimescaleDB installation, hypertable creation,
1,000,000 row ingestion, advanced features, validation, and full cleanup.

Execute all steps as a sudo-privileged user.

============================================================
PART 1 — Install PostgreSQL 17
============================================================

Step 6.1: Install postgresql-common and Configure Official Repository

sudo apt update
sudo apt install -y postgresql-common
sudo /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh
sudo apt update

What this does:
- Updates system packages.
- Installs repository helper.
- Adds official PostgreSQL repository.
- Enables PostgreSQL 17 packages.

------------------------------------------------------------

Step 6.2: Install PostgreSQL 17 Server and Tools

sudo apt install -y postgresql-17 postgresql-client-17 postgresql-contrib-17

What this does:
- Installs PostgreSQL server.
- Installs psql client.
- Installs contrib extensions.

------------------------------------------------------------

Step 6.3: Enable and Start PostgreSQL

sudo systemctl enable postgresql
sudo systemctl start postgresql

What this does:
- Enables service at boot.
- Starts PostgreSQL immediately.

------------------------------------------------------------

Step 6.4: Secure postgres Superuser

sudo -i -u postgres
psql -c "ALTER USER postgres WITH PASSWORD 'password#123456';"
exit

What this does:
- Switches to postgres OS user.
- Sets strong password for database superuser.

------------------------------------------------------------

Step 6.5: Grant Passwordless sudo to postgres OS User

sudo cp /etc/sudoers /etc/sudoers.bak
echo "postgres ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers > /dev/null

What this does:
- Creates backup of sudoers file.
- Allows postgres Linux user to execute sudo without password.

------------------------------------------------------------
PART 2 — Enable Remote Access (0.0.0.0/0)
------------------------------------------------------------

Step 6.6: Allow Listening on All Interfaces

sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/17/main/postgresql.conf

What this does:
- Allows connections from all network interfaces.

------------------------------------------------------------

Step 6.7: Allow All IPv4 Connections

echo "host all all 0.0.0.0/0 scram-sha-256" | sudo tee -a /etc/postgresql/17/main/pg_hba.conf

What this does:
- Allows remote access from any IP.
- Uses SCRAM-SHA-256 authentication.

------------------------------------------------------------

Step 6.8: Restart PostgreSQL

sudo systemctl restart postgresql

What this does:
- Applies configuration changes.

------------------------------------------------------------

Step 6.9: Open Port 5432

sudo ufw allow 5432/tcp

If using AWS Security Group:
Type: PostgreSQL
Protocol: TCP
Port: 5432
Source: 0.0.0.0/0

What this does:
- Allows inbound traffic on PostgreSQL port.

------------------------------------------------------------

Step 6.10: Validate Installation

sudo systemctl status postgresql
ss -tln | grep 5432
sudo -u postgres psql -c "SELECT version();"
sudo -u postgres psql -c "\l" -c "\du"

What this does:
- Confirms service running.
- Confirms port active.
- Displays version and roles.

------------------------------------------------------------

Step 6.11: Test Remote Connectivity

psql -h <SERVER_PUBLIC_IP> -U postgres -d postgres

What this does:
- Confirms remote authentication works.

============================================================
PART 3 — Install TimescaleDB
============================================================

Step 6.12: Install TimescaleDB Package

sudo sh -c "echo 'deb https://packagecloud.io/timescale/timescaledb/ubuntu/ jammy main' > /etc/apt/sources.list.d/timescaledb.list"
wget --quiet -O - https://packagecloud.io/timescale/timescaledb/gpgkey | sudo apt-key add -
sudo apt update
sudo apt install -y timescaledb-2-postgresql-17
psql --version
sudo -u postgres psql -c "CREATE EXTENSION IF NOT EXISTS timescaledb;"

What this does:
- Installs TimescaleDB extension binaries.

------------------------------------------------------------

Step 6.13: Enable shared_preload_libraries

sudo sed -i "s/#shared_preload_libraries = ''/shared_preload_libraries = 'timescaledb'/g" /etc/postgresql/17/main/postgresql.conf

------------------------------------------------------------

Step 6.14: Restart PostgreSQL

sudo systemctl restart postgresql

What this does:
- Loads TimescaleDB background workers.

------------------------------------------------------------

Step 6.15: Validate TimescaleDB Loaded

sudo -u postgres psql -c "SHOW shared_preload_libraries;"

Expected output:
timescaledb

============================================================
PART 4 — Create Time-Series Lab
============================================================

Step 6.16: Create Database and Enable Extension

sudo -u postgres psql

CREATE DATABASE ts_lab;
\c ts_lab
CREATE EXTENSION timescaledb;

------------------------------------------------------------

Step 6.17: Create Schema and Table

CREATE SCHEMA metrics;

CREATE TABLE metrics.sensor_data (
    id BIGSERIAL PRIMARY KEY,
    device_id INT NOT NULL,
    recorded_at TIMESTAMPTZ NOT NULL,
    temperature DOUBLE PRECISION,
    humidity DOUBLE PRECISION
);

------------------------------------------------------------

Step 6.18: Convert to Hypertable

SELECT create_hypertable('metrics.sensor_data','recorded_at');

What this does:
- Enables time-based partitioning.
- Creates internal chunks.

------------------------------------------------------------

Step 6.19: Insert 1,000,000 Rows

INSERT INTO metrics.sensor_data
SELECT generate_series(1,1000000),
       (random()*100)::int,
       NOW() - (random()*200000 || ' seconds')::interval,
       random()*50,
       random()*100;

What this does:
- Simulates large-scale ingestion.
- Inserts 1M rows distributed across chunks.

------------------------------------------------------------

Step 6.20: Create Performance Index

CREATE INDEX idx_time_desc
ON metrics.sensor_data(recorded_at DESC);

------------------------------------------------------------

Step 6.21: Validate Performance

SELECT COUNT(*) FROM metrics.sensor_data;

EXPLAIN ANALYZE
SELECT *
FROM metrics.sensor_data
WHERE recorded_at > NOW() - INTERVAL '1 hour';

============================================================
PART 5 — Advanced Features
============================================================

Step 6.22: Enable Compression

ALTER TABLE metrics.sensor_data
SET (timescaledb.compress, timescaledb.compress_segmentby='device_id');

SELECT add_compression_policy('metrics.sensor_data', INTERVAL '7 days');

------------------------------------------------------------

Step 6.23: Add Retention Policy

SELECT add_retention_policy('metrics.sensor_data', INTERVAL '30 days');

------------------------------------------------------------

Step 6.24: Create Continuous Aggregate

CREATE MATERIALIZED VIEW metrics.hourly_avg
WITH (timescaledb.continuous) AS
SELECT time_bucket('1 hour', recorded_at) AS bucket,
       device_id,
       avg(temperature)
FROM metrics.sensor_data
GROUP BY bucket, device_id;

============================================================
PART 6 — Cleanup Lab
============================================================

Step 6.25: Drop All Objects

DROP MATERIALIZED VIEW metrics.hourly_avg;
DROP TABLE metrics.sensor_data;
DROP SCHEMA metrics CASCADE;
\c postgres
DROP DATABASE ts_lab;

------------------------------------------------------------

Environment includes:
- Repository configuration
- PostgreSQL 17 installation
- Passwordless sudo for postgres OS user
- Remote access (0.0.0.0/0)
- TimescaleDB installation
- Hypertable with 1M rows
- Compression & retention policies
- Continuous aggregates
- Full cleanup
