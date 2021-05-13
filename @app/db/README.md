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
