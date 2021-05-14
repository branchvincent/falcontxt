import { Parser } from 'node-sql-parser'
import { ClientBase } from 'pg'

type MetricDefinition = {
  name: string
  query: string
}

type ColumnConfig = {
  type: 'RAW' | 'METRIC'
  value: string
}

// const getFields = (expr: string): string[] => {
//   const reg = /\("(?<field>[a-zA-Z-_]+)"\)/g
//   const results: string[] = []
//   let match
//   while ((match = reg.exec(expr)) !== null) {
//     results.push(match?.groups?.field as string)
//   }
//   return results
// }

const extractColumns = (query: string): ColumnConfig[] => {
  const parser = new Parser()
  console.log(parser.columnList(`SELECT ${query}`))
  return parser.columnList(`SELECT ${query}`).map((c) => {
    const match = c.match(/select::(?<table>.*)::(?<column>.*)/)
    if (!match || !match.groups || !match.groups.column) {
      throw new Error(`Invalid query: ${query}`)
    }

    const type = match.groups?.table === 'raw' ? 'RAW' : 'METRIC';
    return {
      type,
      value: match.groups.column,
    }
  })
}

const replaceColumns = (query: string, cols: ColumnConfig[]) => {
  return cols.reduce((query, c, idx) => {
    return query.replace(`(${c.value})`, `(r${idx + 1}.data::float)`)
  }, query)
}

export const configureMetricDefinition = async (
  metricDefinition: MetricDefinition,
  pgClient: ClientBase,
): Promise<void> => {
  const { name, query } = metricDefinition
  const cols = extractColumns(query)
  const col = replaceColumns(query, cols)
  await pgClient.query(`drop view if exists app_public.${name}`)
  await pgClient.query(`
        create or replace view app_public.${name} as
        select
            time_bucket(interval '1 minute', time) AS time,
            facility_id,
            '${name}' AS label,
            ${col} AS value
        FROM
          app_public.readings r1
          ${[...Array(cols.length - 1).keys()]
            .map(
              (i) =>
                `JOIN app_public.readings r${i + 2} USING (time, device_id)`,
            )
            .join('\n')}
          JOIN app_public.devices d ON r1.device_id = d.id
        WHERE
          r1.label = '${cols[0]}'
          ${[...Array(cols.length - 1).keys()]
            .map((i) => `AND r${i + 2}.label = '${cols[i + 1]}'`)
            .join('\n')}
        GROUP BY 1, 2;
      `)
  await pgClient.query(
    `create or replace function app_public.facilities_${name}(
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
                max(value) as avg
            from app_public.${name}
            where facility_id = facility.id
            group by 1
        $$ language sql immutable strict;
        `,
  )
}
