import { StockOutlined } from '@ant-design/icons'
import {
  Button,
  Card,
  Col,
  Descriptions,
  Empty,
  Row,
  Skeleton,
  Space,
  Typography,
} from 'antd'
import { FC, useState } from 'react'

import PageHeader from '../../components/PageHeader'
import { MetricDefinition } from '../../graphql'
import { useGetMetricDefinitionsQuery } from '../../queries/types/metricDefinitions'
import { capitalize } from '../../utils/format'
import MetricsDefinitionModal from './MetricsDefinitionModal'

const { Paragraph } = Typography

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
              hoverable={true}
              headStyle={{ backgroundColor: 'rgb(222 222 222)' }}
              onClick={() => setActiveDefinition(metricDefitinion)}
              title={
                <Space>
                  <StockOutlined />
                  {capitalize(metricDefitinion.name)}
                </Space>
              }
            >
              <Descriptions layout="horizontal">
                <Descriptions.Item
                  labelStyle={{ fontWeight: 'bold' }}
                  label="Description"
                >
                  {metricDefitinion?.description || 'None'}
                </Descriptions.Item>
              </Descriptions>
              <Descriptions layout="horizontal">
                <Descriptions.Item
                  labelStyle={{ fontWeight: 'bold' }}
                  label="Units"
                >
                  {metricDefitinion?.units || 'None'}
                </Descriptions.Item>
              </Descriptions>
              <Descriptions layout="horizontal">
                <Descriptions.Item
                  labelStyle={{ fontWeight: 'bold' }}
                  label="Query"
                >
                  <Paragraph>
                    <pre style={{ margin: 0, fontSize: '0.8em' }}>
                      {metricDefitinion.query}
                    </pre>
                  </Paragraph>
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
