# Section 01 -- PostgreSQL Foundations

# Lesson 03 -- Assignment

## Objective

Install PostgreSQL, configure TimescaleDB, create hypertable, insert
data, validate performance, and cleanup.

### Install

sudo apt install -y postgresql-17 sudo apt install -y
timescaledb-2-postgresql-17

Configure shared_preload_libraries = 'timescaledb' Restart PostgreSQL

### Setup

CREATE DATABASE analytics_lab; `\c a`{=tex}nalytics_lab; CREATE
EXTENSION timescaledb;

CREATE SCHEMA telemetry;

CREATE TABLE telemetry.cpu_metrics ( id BIGSERIAL PRIMARY KEY, host_name
TEXT NOT NULL, recorded_at TIMESTAMPTZ NOT NULL, cpu_usage DOUBLE
PRECISION NOT NULL );

SELECT create_hypertable('telemetry.cpu_metrics','recorded_at');

CREATE INDEX idx_cpu_time ON telemetry.cpu_metrics(recorded_at DESC);

INSERT INTO telemetry.cpu_metrics SELECT generate_series(1,500000),
'server\_' \|\| (random()*10)::int, NOW() - (random()*10000 \|\| '
seconds')::interval, random()\*100;

SELECT COUNT(\*) FROM telemetry.cpu_metrics;

EXPLAIN ANALYZE SELECT \* FROM telemetry.cpu_metrics WHERE recorded_at
\> NOW() - INTERVAL '2 hours';

### CLEANUP

DROP TABLE telemetry.cpu_metrics; DROP SCHEMA telemetry CASCADE;
`\c p`{=tex}ostgres DROP DATABASE analytics_lab;
