import { Line } from '@ant-design/charts'
import { DatePicker, Spin } from 'antd'
import { FC } from 'react'
import { useEffect, useState } from 'react'

import PageHeader from '../../components/PageHeader'
import { useGetMetricsByTimeLazyQuery } from '../../queries/types/metrics'

const { RangePicker } = DatePicker

const Metrics: FC = () => {
  const [dateRange, setDateRange] = useState<[string, string]>([
    '2021-05-01',
    '2021-06-01',
  ])
  const [getMetrics, { data, loading }] = useGetMetricsByTimeLazyQuery()

  useEffect(() => {
    const [from, to] = dateRange
    getMetrics({ variables: { from, to } })
  }, [getMetrics, dateRange])

  if (loading) return <Spin />
  return (
    <div>
      <PageHeader title="Metrics" subTitle="View insights through metrics" />
      <RangePicker
        picker="week"
        onChange={(dates, dateStrings) => {
          setDateRange(dateStrings)
        }}
      />
      <Line
        data={data?.readings?.nodes || []}
        xField="time"
        yField="data"
        xAxis={{ tickCount: 5 }}
        slider={{ start: 0.1, end: 0.5 }}
      />
    </div>
  )
}

export default Metrics
