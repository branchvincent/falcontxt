// See https://github.com/graphile/postgraphile/blob/v4/examples/servers/common.ts
import PgSimplifyInflectorPlugin from '@graphile-contrib/pg-simplify-inflector'
import type { Pool } from 'pg'
import { PostGraphileOptions } from 'postgraphile'

import ExtendedSchemaPlugin from './graphql'

// Connection string (or pg.Pool) for PostGraphile to use
export const database: string | Pool =
  process.env.DATABASE_URL || 'postgres://user:pass@localhost:5432/db'

// Database schemas to use
export const schemas: string | string[] = ['app_public']

// PostGraphile options; see https://www.graphile.org/postgraphile/usage-library/#api-postgraphilepgconfig-schemaname-options
export const options: PostGraphileOptions = {
  pgSettings(req) {
    // Adding this to ensure that all servers pass through the request in a
    // good enough way that we can extract headers.
    // CREATE FUNCTION current_user_id() RETURNS text AS $$ SELECT current_setting('graphile.test.x-user-id', TRUE); $$ LANGUAGE sql STABLE;
    return {
      role: process.env.DATABASE_VISITOR,
      'graphile.test.x-user-id':
        req.headers['x-user-id'] ||
        // `normalizedConnectionParams` comes from websocket connections, where
        // the headers often cannot be customized by the client.
        // eslint-disable-next-line  @typescript-eslint/no-explicit-any
        (req as any).normalizedConnectionParams?.['x-user-id'],
    }
  },
  watchPg: true,
  graphiql: true,
  enhanceGraphiql: true,
  subscriptions: true,
  dynamicJson: true,
  setofFunctionsContainNulls: false,
  ignoreRBAC: false,
  showErrorStack: 'json',
  extendedErrors: ['hint', 'detail', 'errcode'],
  allowExplain: true,
  legacyRelations: 'omit',
  exportGqlSchemaPath: `${__dirname}/../schema.graphql`,
  sortExport: true,
  enableQueryBatching: true,
  appendPlugins: [PgSimplifyInflectorPlugin, ExtendedSchemaPlugin],
}

// Server port
export const port: number = process.env.PORT
  ? parseInt(process.env.PORT, 10)
  : 3000
