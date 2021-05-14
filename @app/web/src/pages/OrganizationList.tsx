import { FC } from 'react';
import { Card, Col, Row, Skeleton, Empty } from 'antd';
import { useGetOrganizationsQuery } from '../queries/types/organizations';

const OrganizationList : FC = () => {
  const { data, loading } = useGetOrganizationsQuery();
  return (
    <div>
      { loading ? <Skeleton active={true} className="nio-skeleton"/> : null }
      { !data?.organizations?.nodes.length ? <Empty /> : null}
      <Row gutter={16}>
          {
            data?.organizations?.nodes.map((organization) => 
              <Col span={8} key={organization.slug}>
                <Card title={organization.name}>
                  slug: { organization.slug}
                  facilityCount: { organization.facilities.totalCount }
                </Card>
              </Col>
            )  
          }
      </Row>
    </div>
  )
};

export default OrganizationList;