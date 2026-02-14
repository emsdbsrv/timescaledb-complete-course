
# Lesson_07_Continuous_Aggregates_Deep_Dive_Assignment

## Objective
Implement and analyze continuous aggregates.

## Tasks
1. Create hypertable with 2 million rows.
2. Create daily continuous aggregate.
3. Compare raw vs aggregate query performance.
4. Add automatic refresh policy.
5. Add index on bucket column.
6. Drop database after completion.

## Cleanup
psql -d postgres -c "DROP DATABASE IF EXISTS assignment_cagg_lab;"
