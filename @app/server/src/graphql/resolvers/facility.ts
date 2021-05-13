interface MetricArgs {
  name: string
  start?: string
  end?: string
  interval?: string
}
interface Metric {
  time: string
  label: string
  data: number
}

export default {
  Facility: {
    metric: async (
      _query: any,
      args: MetricArgs,
      context: any,
      resolveInfo: any,
    ): Promise<Metric[]> => {
      const { pgClient } = context
      const {
        name,
        start = '2020-01-01',
        end = '2021-01-01',
        interval = '5 min',
      } = args || {}
      const { rows } = await pgClient.query(
        `
        select t::text AS time, $1 AS label, floor(random() * 100) AS data
        from generate_series($2::timestamptz, $3::timestamptz, $4::interval) t
        `,
        [name, start, end, interval],
      )
      return rows
    },
  },
}
