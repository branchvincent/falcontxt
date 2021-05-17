import { Parser } from 'node-sql-parser'
import { ClientBase } from 'pg'

import { InvalidExpressionError } from '../errors'
import { camelize, camelToSnakeCase } from '../utils/format'

type MetricDefinition = {
  name: string
  query: string
}

type ColumnConfig = {
  type: 'RAW' | 'METRIC'
  value: string
  alias: string
}

const parser = new Parser()
const allowedTableNames = new Set(['raw', 'null'])

const extractUniqueColumns = (query: string): ColumnConfig[] => {
  const aliasSet = new Set()
  const columnSet = new Set()
  try {
    return parser
      .columnList(`SELECT ${query}`)
      .reduce<ColumnConfig[]>((acc, c) => {
        const match = c.match(/select::(?<table>.*)::(?<column>.*)/)
        if (!match || !match.groups || !match.groups.column) {
          throw new Error(`Invalid query: ${query}`)
        }

        const { column, table } = match.groups

        if (columnSet.has(column)) {
          return acc
        }

        if (table && !allowedTableNames.has(table)) {
          throw new InvalidExpressionError(
            `Invalid column expression: ${table}.${column}`,
          )
        }

        const type = table === 'raw' ? 'RAW' : 'METRIC'
        const firstChar = column.charAt(0)
        let index = 1
        while (aliasSet.has(`${firstChar}${index}`)) {
          index++
        }

        columnSet.add(column)
        aliasSet.add(`${firstChar}${index}`)
        const colConfig: ColumnConfig = {
          type,
          value: column,
          alias: `${firstChar}${index}`,
        }

        return [...acc, colConfig]
      }, [])
  } catch (e) {
    throw new InvalidExpressionError(e.message)
  }
}

const generateViewQuery = (name: string, query: string) => {
  const cols = extractUniqueColumns(query)
  if (!cols.length) {
    throw new InvalidExpressionError(
      'At least one parseable metric name must be provided.',
    )
  }

  const resultingQuery = cols.reduce((query, c) => {
    return query
      .split(`(${c.type === 'RAW' ? 'raw.' : ''}${c.value.toLowerCase()})`)
      .join(`(${c.alias}.value::float)`)
  }, query.toLowerCase())

  const createRawStatement = (column: ColumnConfig) => `
    ${column.value} as (
      SELECT
        time_bucket (interval '1 minute', time) AS time,
        d.facility_id,
        r.label,
        avg(r.data::float) AS value
      FROM
          app_public.readings r
          JOIN app_public.devices d ON r.device_id = d.id
      WHERE
          r.label = '${column.value}'
      GROUP BY 1,2,3
    )
  `

  const createAliasStatment = (column: ColumnConfig) =>
    `${column.type !== 'RAW' ? 'app_public.' : ''}${camelToSnakeCase(
      camelize(column.value),
    )} ${column.alias}`

  const rawStatements = cols
    .filter((col) => col.type === 'RAW')
    .map(createRawStatement)

  const aliasStatements = cols
    .map(createAliasStatment)
    .reduce((acc, statement) => {
      let newStatement = statement
      if (acc.length) {
        newStatement = `JOIN ${newStatement} USING (time, facility_id)`
      }

      return `${acc}\n${newStatement}`
    }, '')

  return `
    CREATE OR REPLACE VIEW app_public.${name} as ${
    rawStatements.length
      ? `
      WITH ${rawStatements.join(', ')}
    `
      : ''
  }
    SELECT
      time_bucket (interval '1 minute', time) AS time,
      ${cols[0].alias}.facility_id,
      ${resultingQuery} as value
    FROM
      ${aliasStatements}
    GROUP BY 1,2;
  `
}

const generateMetricFunctions = (name: string): string[] => [
  `
  create or replace function app_public.facilities_${name}(
    facility app_public.facilities,
    "from" timestamptz,
    "to" timestamptz default now(),
    "interval" interval default '1 hour'
  ) returns setof app_public.metric as $$
    select
        time_bucket(interval, time) as time,
        count(*),
        first(value, time),
        last(value, time),
        avg(value) as avg,
        sum(value) as sum,
        min(value) as min,
        max(value) as max
    from app_public.${name}
    where facility_id = facility.id
    group by 1
  $$ language sql immutable strict;
`,
]

export const fixMetricDefinitionArgs = (metricDefinition: {
  [key: string]: any
}): { [key: string]: any } => {
  const { query, name, ...rest } = metricDefinition
  return {
    query,
    name: camelize(name),
    ...rest,
  }
}

export const configureMetricDefinition = async (
  metricDefinition: MetricDefinition,
  pgClient: ClientBase,
): Promise<void> => {
  const { name, query } = metricDefinition
  const snakeCaseName = camelToSnakeCase(name)
  await pgClient.query(`drop view if exists app_public.${snakeCaseName}`)
  await pgClient.query(generateViewQuery(snakeCaseName, query))
  await Promise.all(
    generateMetricFunctions(snakeCaseName).map((query) =>
      pgClient.query(query),
    ),
  )
}
