# Lesson_03_Creating_Time_Series_Lab_DB Assignment

## Objective

Install PostgreSQL, enable remote access, install TimescaleDB, create
hypertable, insert data, validate performance, and clean up environment.

------------------------------------------------------------------------

## Tasks

1.  Install PostgreSQL 17 using PGDG repository.
2.  Secure postgres role with strong password.
3.  Enable remote access using /32 rule.
4.  Open firewall port 5432.
5.  Install timescaledb-2-postgresql-17.
6.  Configure shared_preload_libraries.
7.  Restart PostgreSQL.
8.  Create database analytics_lab.
9.  Enable timescaledb extension.
10. Create schema telemetry.
11. Create cpu_metrics hypertable.
12. Insert 500000 rows.
13. Run EXPLAIN ANALYZE query.
14. Drop table, schema, and database.

------------------------------------------------------------------------

## Cleanup Commands

DROP TABLE telemetry.cpu_metrics; DROP SCHEMA telemetry CASCADE;
`\c p`{=tex}ostgres; DROP DATABASE analytics_lab;

------------------------------------------------------------------------

## Deliverables

• Installation log • Extension validation (`\dx`{=tex}) • Execution plan
output • Cleanup confirmation
