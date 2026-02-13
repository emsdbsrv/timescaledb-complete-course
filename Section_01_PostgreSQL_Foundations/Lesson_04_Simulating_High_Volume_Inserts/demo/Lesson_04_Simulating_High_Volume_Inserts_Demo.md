# Lesson 04 -- Simulating High Volume Inserts

## Table of Contents

1.  Introduction
2.  What You Will Do
3.  Prerequisites
4.  Best Practices
5.  Real-World Production Scenario
6.  Step-by-Step Setup
7.  20 Common PostgreSQL Commands
8.  10 Questions and Answers
9.  5 Real-Time Interview Scenarios
10. Summary

------------------------------------------------------------------------

## 1. Introduction

This lesson focuses on simulating high-volume inserts in PostgreSQL and
TimescaleDB to understand ingestion performance and system behavior
under load.

------------------------------------------------------------------------

## 6. Step-by-Step Setup

### Enable Timing

``` sql
\timing
```

### Insert 1 Million Rows

``` sql
INSERT INTO metrics.sensor_data
SELECT
    generate_series(1,1000000),
    (random()*20)::int,
    NOW() - (random()*50000 || ' seconds')::interval,
    random()*60,
    random()*100;
```

### Validate Row Count

``` sql
SELECT COUNT(*) FROM metrics.sensor_data;
```

### Analyze Query Performance

``` sql
EXPLAIN ANALYZE
SELECT *
FROM metrics.sensor_data
WHERE recorded_at > NOW() - INTERVAL '1 hour';
```

------------------------------------------------------------------------

## 10. Summary

You simulated large-scale ingestion.

You measured performance impact.

You validated index influence.

You observed WAL and checkpoint behavior.

You prepared system for production tuning.
