import { QuestionCircleOutlined } from '@ant-design/icons'
import { Table, Tag, Tooltip, Typography } from 'antd'
import { FC } from 'react'

import { MetricDefinition } from '../../graphql'
import { useGetFacilityRankingsQuery } from '../../queries/types/overview'
import { camelToSnakeCase, capitalize } from '../../utils/format'

const { Text } = Typography

type MetricRankTableProps = {
  metricDefinition: MetricDefinition
  tags: string[]
}

const MetricRankTable: FC<MetricRankTableProps> = ({
  metricDefinition,
  tags,
}) => {
  const { data, loading } = useGetFacilityRankingsQuery({
    variables: {
      metric: camelToSnakeCase(metricDefinition.name),
      tags,
    },
    fetchPolicy: 'network-only',
  })

  return (
    <Table
      loading={loading}
      bordered
      size="small"
      pagination={false}
      title={() => (
        <span>
          <Text strong>Metric: </Text>
          <Text>{capitalize(metricDefinition.name)}</Text>
          {metricDefinition?.description ? (
            <Tooltip title={metricDefinition?.description}>
              <QuestionCircleOutlined style={{ float: 'right' }} />
            </Tooltip>
          ) : null}
        </span>
      )}
      columns={[
        {
          title: 'Rank',
          dataIndex: 'rank',
          key: 'rank',
          width: 20,
          align: 'center',
        },
        {
          title: 'Facility',
          dataIndex: 'slug',
          key: 'facility',
          align: 'center',
          sorter: (a, b) => a.slug!.localeCompare(b.slug),
        },
        {
          title: `Value${
            metricDefinition.units ? `(${metricDefinition.units})` : ''
          }`,
          dataIndex: 'value',
          key: 'value',
          render: (value: number) =>
            Math.round((value + Number.EPSILON) * 100) / 100,
          align: 'right',
          sorter: (a, b) => a.value! - b.value!,
          defaultSortOrder: 'descend',
        },
        {
          title: 'Tags',
          key: 'tags',
          dataIndex: 'tags',
          render: (tags: string[]) => (
            <>
              {tags.map((tag) => (
                <Tag key={tag}>{tag}</Tag>
              ))}
            </>
          ),
        },
      ]}
      dataSource={
        data?.facilityRankings?.nodes.map(({ facility, ...rest }) => ({
          slug: facility!.slug,
          ...rest,
        })) || []
      }
    ></Table>
  )
}

export default MetricRankTable
