import { Card, Col, Empty,Row, Skeleton } from 'antd';
import { FC } from 'react';

import { useOrganizationContext } from '../components/OrganizationContext';
import { useGetFacilitiesByOrganizationQuery } from '../queries/types/facilities';

const FacilityList : FC = () => {
  const { current } = useOrganizationContext(); 
  const {data, loading} = useGetFacilitiesByOrganizationQuery({ variables: { slug: current!.slug}});

  return (
    <div>
      { loading ? <Skeleton active={true} className="nio-skeleton"/> : null }
      { !data?.organizationBySlug?.facilities?.nodes.length ? <Empty /> : null}
      <Row gutter={16}>
          {
            data?.organizationBySlug?.facilities?.nodes.map((facility) => 
              <Col span={8} key={facility.slug}>
                <Card title={facility.name}>
                  slug: { facility.slug}
                </Card>
              </Col>
            )  
          }
      </Row>
    </div>
  )
};

export default FacilityList;