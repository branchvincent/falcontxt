import {
  Button,
  Card,
  Col,
  Descriptions,
  Empty,
  Row,
  Skeleton,
  Tag,
} from 'antd'
import { FC, useState } from 'react'

import { useOrganizationContext } from '../../components/OrganizationContext'
import PageHeader from '../../components/PageHeader'
import { Facility } from '../../graphql'
import { useGetFacilitiesByOrganizationQuery } from '../../queries/types/facilities'
import FacilityModal from './FacilityModal'

const FacilityList: FC = () => {
  const [activeFacility, setActiveFacility] = useState<Partial<Facility>>()
  const { current } = useOrganizationContext()
  const { data, loading } = useGetFacilitiesByOrganizationQuery({
    variables: { slug: current!.slug },
  })

  return (
    <div>
      {activeFacility ? (
        <FacilityModal
          facility={activeFacility}
          onComplete={() => setActiveFacility(undefined)}
        />
      ) : null}
      <PageHeader
        title="Facilities"
        subTitle="View current facilities in your organization"
        extra={[
          <Button key="3" type="primary" onClick={() => setActiveFacility({})}>
            Create
          </Button>,
        ]}
      />
      {loading ? <Skeleton active={true} className="nio-skeleton" /> : null}
      {!data?.organizationBySlug?.facilities?.nodes.length ? <Empty /> : null}
      <Row gutter={[16, 16]}>
        {data?.organizationBySlug?.facilities?.nodes.map((facility) => (
          <Col span={8} key={facility.slug}>
            <Card
              hoverable={true}
              headStyle={{ backgroundColor: 'rgb(222 222 222)' }}
              onClick={() => setActiveFacility(facility)}
              title={facility.name}
            >
              <Descriptions layout="horizontal">
                <Descriptions.Item
                  labelStyle={{ fontWeight: 'bold' }}
                  label="Slug"
                >
                  {facility.slug}
                </Descriptions.Item>
              </Descriptions>
              <>
                {facility.tags?.map((tag) => (
                  <Tag key={tag}>{tag}</Tag>
                ))}
              </>
            </Card>
          </Col>
        ))}
      </Row>
    </div>
  )
}

export default FacilityList
