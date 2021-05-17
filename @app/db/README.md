# @app/db

## Migrations

Database migrations are handled via [Graphile Migrate](https://github.com/graphile/migrate).

## Hooks

- `afterReset`: Executed after creating/reseting db but before migrations
- `afterAllMigrations`: Executed after migrations
- `afterCurrent`: Executed after `current.sql`

## Roles

- `DATABASE_OWNER`: Runs migrations
- `DATABASE_AUTHENTICATOR`: Initially serves a request by connecting to the database and immediately switches to `DATABASE_VISITOR`
- `DATABASE_VISITOR`: Actually serves requests by running the SQL queries

## Seed

Seed data was generated via:

```sql
WITH facility AS (
    SELECT
        *
    FROM
        facilities
    WHERE
        name IN ('Geneva (CC: 100155)', 'Manteca (CC: 100113)', 'Oxnard (CC: 100117)', 'Batavia (CC: 100154)', 'Springfield (CC: 100177)')
),
metric AS (
    SELECT
        m.*
    FROM
        asset_metrics m,
        facility f
    WHERE
        m.label IN ('facility_daily_utility_energy_spend', 'facility_daily_utility_energy_usage', 'facility_daily_revenue')
        AND m.organization_id = f.organization_id
)
SELECT
    mv.effective_start_date AS time,
    f.id AS device_id,
    m.label,
    avg(mv.value::float) AS data
FROM
    asset_metric_values mv,
    facility f,
    metric m
WHERE
    mv.asset_id = f.asset_id
    AND mv.asset_metric_id = m.id
    AND effective_start_date >= '2020-01-01'
GROUP BY 1, 2, 3
ORDER BY 1;
```
