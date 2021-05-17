import { Line } from '@ant-design/charts'
import { QuestionCircleFilled } from '@ant-design/icons'
import { Alert, DatePicker, Select, Tooltip } from 'antd'
import { capitalize } from 'lodash'
import moment, { Moment } from 'moment'
import React, { FC, useEffect, useState } from 'react'

import PageHeader from '../../components/PageHeader'
import { useGetMetricDefinitionsQuery } from '../../queries/types/metricDefinitions'
import { useGetFacilityMetricsLazyQuery } from '../../queries/types/metrics'

const { RangePicker } = DatePicker
const { Option } = Select

const initialRange = { from: moment().subtract(1, 'months'), to: moment() }

const Metrics: FC = () => {
  const [metric, setMetric] = useState<string>()
  const [range, setRange] = useState<{ from: Moment; to: Moment }>(initialRange)
  const { data: metrics } = useGetMetricDefinitionsQuery()
  const [getMetricData, { data, loading, error }] =
    useGetFacilityMetricsLazyQuery()

  useEffect(() => {
    if (metric && range) {
      getMetricData({ variables: { ...range, name: metric } })
    }
  }, [metric, range, getMetricData])

  const currMetric = metrics?.metricDefinitions?.nodes.find(
    ({ name }) => name == metric,
  )
  const metricData = data?.facilities?.nodes.reduce<Record<string, any>[]>(
    (acc, facility) => {
      const metrics = facility.metrics?.nodes || []
      return [
        ...acc,
        ...metrics.reduce<Record<string, any>[]>(
          (acc2, m) => [...acc2, { ...m, slug: facility.slug }],
          [],
        ),
      ]
    },
    [],
  )

  return (
    <div>
      <PageHeader title="Metrics" subTitle="View insights through metrics" />
      <Select
        style={{ margin: 20, width: 160 }}
        placeholder="Select a metric"
        defaultValue={metric}
        onChange={(m) => setMetric(m)}
      >
        {metrics?.metricDefinitions?.nodes.map(({ name }) => (
          <Option key={name} value={name}>
            {name}
          </Option>
        ))}
      </Select>
      <RangePicker
        style={{ margin: 20, float: 'right' }}
        format="YYYY/MM/DD"
        defaultValue={[range.from, range.to]}
        onChange={(range) => {
          const [from, to] = range || []
          if (from && to) setRange({ from, to })
        }}
      />
      {error ? (
        <Alert
          message="Error"
          description={`An unexpected error occurred: ${error.message}`}
          type="error"
          showIcon
        />
      ) : null}
      {!error && !loading && metricData ? (
        <div>
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            {capitalize(currMetric?.name)}
            <Tooltip title={currMetric?.description}>
              <QuestionCircleFilled style={{ margin: 5 }} />
            </Tooltip>
          </div>
          <Line
            data={metricData || []}
            xField="time"
            yField="avg"
            seriesField="slug"
            xAxis={{
              title: { text: 'Time' },
              label: {
                formatter: (text: string) => moment(text).format('YYYY/MM/DD'),
              },
            }}
            yAxis={
              currMetric
                ? {
                    title: {
                      text: `${currMetric?.name} (${
                        currMetric?.units || 'n/a'
                      })`,
                    },
                  }
                : {}
            }
          />
        </div>
      ) : null}
    </div>
  )
}

export default Metrics
