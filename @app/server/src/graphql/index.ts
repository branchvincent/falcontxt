import { makeExtendSchemaPlugin, makeWrapResolversPlugin } from 'graphile-utils'
import { Parser } from 'node-sql-parser'

import getResolvers from './resolvers'
import getTypeDefs from './types'

const getFields = (expr: string): string[] => {
  const reg = /\("(?<field>[a-zA-Z-_]+)"\)/g
  const results: string[] = []
  let match
  while ((match = reg.exec(expr)) !== null) {
    results.push(match?.groups?.field as string)
  }
  return results
}

const extractColumns = (query: string): string[] => {
  const parser = new Parser()
  console.log(parser.columnList(`SELECT ${query}`))
  return parser
    .columnList(`SELECT ${query}`)
    .map((c) => c.match(/select::.*::(?<column>.*)/)!.groups!.column)
}

const replaceColumns = (query: string, cols: string[]) => {
  return cols.reduce((query, c, idx) => {
    return query.replace(`(${c})`, `(r${idx + 1}.data::float)`)
  }, query)
}

export const extendSchema = makeExtendSchemaPlugin(() => {
  return {
    typeDefs: getTypeDefs(),
    resolvers: getResolvers(),
  }
})

export const extendResolvers = makeWrapResolversPlugin({
  Mutation: {
    createMetricDefinition: async (
      resolve,
      source,
      args,
      context,
      resolveInfo,
    ) => {
      const result = await resolve(source, args, context, resolveInfo)
      const { pgClient } = context
      const { name, query } = args?.input.metricDefinition
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
      return result
    },
  },
})
