import { QuestionCircleOutlined } from '@ant-design/icons'
import { Table, Tag, Tooltip, Typography } from 'antd'
import { FC } from 'react'

import { MetricDefinition } from '../../graphql'
import { capitalize } from '../../utils/format'

const { Text } = Typography

type MetricRankTableProps = {
  metricDefinition: MetricDefinition
}

const MetricRankTable: FC<MetricRankTableProps> = ({ metricDefinition }) => {
  return (
    <Table
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
        },
        {
          title: 'Facility',
          dataIndex: 'facility',
          key: 'facility',
        },
        {
          title: `Value${
            metricDefinition.units ? `(${metricDefinition.units})` : ''
          }`,
          dataIndex: 'value',
          key: 'value',
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
      dataSource={[
        {
          rank: '1',
          key: '1',
          facility: 'Test1',
          value: 32,
          tags: ['test1'],
        },
        {
          rank: '2',
          key: '2',
          facility: 'Test2',
          value: 32,
          tags: ['test2'],
        },
      ]}
    ></Table>
  )
}

export default MetricRankTable
