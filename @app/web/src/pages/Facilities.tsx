import { FC, useEffect } from 'react';
import { Card, Col, Row, Skeleton, Empty } from 'antd';
import { useGetFacilitiesByOrganizationLazyQuery } from '../queries/types/facilities';
import useOrganizationContext from '../hooks/useOrganizationContext';

const FacilityList : FC = () => {
  const { currentOrganization, loading: contextLoading } = useOrganizationContext(); 
  const [getFacilities, {data, loading}] = useGetFacilitiesByOrganizationLazyQuery();

  useEffect(() => {
    if (currentOrganization) {
      getFacilities({ variables: { slug: currentOrganization.slug }})
    }
  }, [currentOrganization, getFacilities]);

  return (
    <div>
      { loading || contextLoading ? <Skeleton active={true} className="nio-skeleton"/> : null }
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