import { EditOutlined } from '@ant-design/icons'
import { Button, Card, Col, Descriptions, Empty, Row, Skeleton } from 'antd'
import { FC, useState } from 'react'

import PageHeader from '../../components/PageHeader'
import { MetricDefinition } from '../../graphql'
import { useGetMetricDefinitionsQuery } from '../../queries/types/metricDefinitions'
import MetricsDefinitionModal from './MetricsDefinitionModal'

const MetricDefitinions: FC = () => {
  const [activeDefinition, setActiveDefinition] =
    useState<Partial<MetricDefinition>>()
  const { data, loading } = useGetMetricDefinitionsQuery()

  return (
    <div>
      {activeDefinition ? (
        <MetricsDefinitionModal
          definition={activeDefinition}
          onComplete={() => setActiveDefinition(undefined)}
        />
      ) : null}
      <PageHeader
        title="Metric Definitions"
        subTitle="Define metric definitions to customize insights"
        extra={[
          <Button
            key="3"
            type="primary"
            onClick={() => setActiveDefinition({})}
          >
            Create
          </Button>,
        ]}
      />
      {loading ? <Skeleton active={true} className="nio-skeleton" /> : null}
      {!loading && !data?.metricDefinitions?.nodes.length ? <Empty /> : null}
      <Row gutter={[16, 16]}>
        {data?.metricDefinitions?.nodes.map((metricDefitinion) => (
          <Col span={8} key={metricDefitinion.name}>
            <Card
              title={metricDefitinion.name}
              extra={
                <EditOutlined
                  onClick={() => setActiveDefinition(metricDefitinion)}
                />
              }
            >
              <Descriptions layout="horizontal">
                <Descriptions.Item label="Description">
                  {metricDefitinion.description}
                </Descriptions.Item>
              </Descriptions>
              <Descriptions layout="horizontal">
                <Descriptions.Item label="Query">
                  {metricDefitinion.query}
                </Descriptions.Item>
              </Descriptions>
            </Card>
          </Col>
        ))}
      </Row>
    </div>
  )
}

export default MetricDefitinions
