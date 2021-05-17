import { Col, Divider, Empty, Row, Skeleton, Tag } from 'antd'
import { FC, useCallback, useState } from 'react'

import PageHeader from '../../components/PageHeader'
import { MetricDefinition } from '../../graphql'
import { useGetDistinctTagsQuery } from '../../queries/types/facilities'
import { useGetMetricDefinitionsQuery } from '../../queries/types/metricDefinitions'
import MetricRankTable from './MetricRankTable'

const { CheckableTag } = Tag

const Overview: FC = () => {
  const [activeTags, setActiveTags] = useState<Set<string>>(new Set())
  const { data: distinctTags, loading: tagsLoading } = useGetDistinctTagsQuery()
  const { data: metricDefitions, loading: metricDefinitionsLoading } =
    useGetMetricDefinitionsQuery()
  const appendOrRemoveTag = useCallback(
    (tag: string, enabled: boolean) => {
      const newSet = new Set(activeTags)
      if (enabled) {
        newSet.add(tag)
      } else {
        newSet.delete(tag)
      }
      setActiveTags(newSet)
    },
    [activeTags, setActiveTags],
  )

  return (
    <div>
      <PageHeader title="Overview" subTitle="View metrics across facilities" />
      <div>
        <b style={{ marginRight: '10px' }}>Tags: </b>
        {distinctTags?.facilityDistinctTags?.map((tag) => (
          <CheckableTag
            key={tag}
            checked={activeTags.has(tag!)}
            onChange={(checked) => appendOrRemoveTag(tag!, checked)}
          >
            {tag}
          </CheckableTag>
        ))}
      </div>
      <Divider />
      {tagsLoading || metricDefinitionsLoading ? (
        <Skeleton active={true} className="nio-skeleton" />
      ) : null}
      {!metricDefinitionsLoading &&
      !metricDefitions?.metricDefinitions?.nodes.length ? (
        <Empty />
      ) : null}
      {metricDefitions?.metricDefinitions?.nodes.length ? (
        <Row gutter={[16, 16]}>
          {metricDefitions.metricDefinitions.nodes.map((metricDefinition) => (
            <Col span={12} key={metricDefinition.id}>
              <MetricRankTable
                metricDefinition={metricDefinition as MetricDefinition}
                tags={Array.from(activeTags)}
              />
            </Col>
          ))}
        </Row>
      ) : null}
    </div>
  )
}

export default Overview
