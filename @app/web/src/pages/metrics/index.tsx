import { Line } from '@ant-design/charts'
import {
  DownloadOutlined,
  InfoCircleOutlined,
  QuestionCircleFilled,
} from '@ant-design/icons'
import { Alert, Button, DatePicker, Select, Spin, Table, Tooltip } from 'antd'
import { capitalize } from 'lodash'
import moment from 'moment'
import React, { FC, useEffect, useState } from 'react'

import PageHeader from '../../components/PageHeader'
import {
  useGetFacilityMetricsLazyQuery,
  useGetMetricsNamesQuery,
} from '../../queries/types/metrics'

const { RangePicker } = DatePicker
const { Option } = Select

const range = { from: moment().subtract(1, 'months'), to: moment() }
const columns = [{ title: 'time' }, { title: 'data' }]

const Metrics: FC = () => {
  // const [range, setRange] = useState<{ from: string; to: string }>()
  const [metric, setMetric] = useState<string>()
  const { data: metrics, loading: metricsLoading } = useGetMetricsNamesQuery()
  const [getMetricData, { data, loading, error }] =
    useGetFacilityMetricsLazyQuery()

  useEffect(() => {
    if (metric && range) {
      getMetricData({ variables: { ...range, name: metric } })
    }
  }, [metric, range, getMetricData])

  // if (metricsLoading || loading) return <Spin />
  const metricData = data?.facilities?.nodes.reduce<Record<string, string>[]>(
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
  console.log(metricData)
  // const metricData = data?.facilities?.nodes[0].metrics?.nodes || []
  const currMetric = metrics?.metricDefinitions?.nodes.find(
    ({ name }) => name == metric,
  )
  return (
    <div>
      <PageHeader title="Metrics" subTitle="View insights through metrics" />
      <Select
        style={{ margin: 20, width: 160 }}
        placeholder="Select a metric"
        onChange={(m: string) => setMetric(m)}
      >
        {metrics?.metricDefinitions?.nodes.map(({ name }) => (
          <Option key={name} value={name}>
            {name}
          </Option>
        ))}
      </Select>
      <RangePicker
        style={{ margin: 20 }}
        format="YYYY/MM/DD"
        defaultValue={[moment().subtract(1, 'months'), moment()]}
        // defaultPickerValue={[moment().subtract(1, 'months'), moment()]}
        // onChange={(range) => {
        //   if (range && range[0] && range[1]) {
        //     setRange({
        //       from: range[0].toISOString(),
        //       to: range[1].toISOString(),
        //     })
        //   }
        // }}
      />
      <Button icon={<DownloadOutlined />} style={{ float: 'right' }}>
        Download CSV
      </Button>
      {error ? (
        <Alert
          message="Error"
          description={`An unexpected error occurred: ${error.message}`}
          type="error"
          showIcon
        />
      ) : null}
      {!error ? (
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
      {/* {!error ? (
        <Table columns={columns} dataSource={metricData} /> //onChange={onChange} />
      ) : null} */}
    </div>
  )
}

export default Metrics
