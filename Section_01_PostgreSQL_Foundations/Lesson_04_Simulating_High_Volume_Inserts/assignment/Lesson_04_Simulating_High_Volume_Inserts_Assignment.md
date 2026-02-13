# Lesson 04 -- Simulating High Volume Inserts Assignment

## Objective

Simulate 2 million row ingestion and measure performance impact.

------------------------------------------------------------------------

## Step 1 -- Insert Data

``` sql
INSERT INTO metrics.sensor_data
SELECT
    generate_series(1,2000000),
    (random()*30)::int,
    NOW() - (random()*100000 || ' seconds')::interval,
    random()*70,
    random()*100;
```

------------------------------------------------------------------------

## Step 2 -- Measure Timing

``` sql
\timing
SELECT COUNT(*) FROM metrics.sensor_data;
```

------------------------------------------------------------------------

## Step 3 -- Drop Index and Re-test

``` sql
DROP INDEX idx_sensor_time;

INSERT INTO metrics.sensor_data
SELECT
    generate_series(1,500000),
    (random()*30)::int,
    NOW() - (random()*20000 || ' seconds')::interval,
    random()*70,
    random()*100;
```

------------------------------------------------------------------------

## Step 4 -- Recreate Index

``` sql
CREATE INDEX idx_sensor_time
ON metrics.sensor_data(recorded_at DESC);
```

------------------------------------------------------------------------

## Step 5 -- Analyze Performance

``` sql
EXPLAIN ANALYZE
SELECT *
FROM metrics.sensor_data
WHERE recorded_at > NOW() - INTERVAL '2 hours';
```

------------------------------------------------------------------------

## Deliverables

• Insert timing results

• Execution plan output

• Comparison with and without index

• WAL directory observation notes

• Final SQL script
