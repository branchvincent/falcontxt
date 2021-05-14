import { FC } from 'react';
import { Button, Dropdown, Menu, Spin } from 'antd';
import { useGetOrganizationsQuery } from '../queries/types/organizations';
import useOrganizationContext from '../hooks/useOrganizationContext';

const OrganizationDropdown : FC = () => {
  const { currentOrganization, loading: contextLoading } = useOrganizationContext();
  const { changeOrganization } = useOrganizationContext();
  const { data, loading } = useGetOrganizationsQuery();

  const organizations = (
    <Menu>
      { data?.organizations?.nodes.map((organization) => 
        <Menu.Item key={`${organization.slug}`} onClick={() => changeOrganization(organization.slug) }>
          { organization.name }
        </Menu.Item>
      )}
    </Menu>
  )

  const current = currentOrganization ? currentOrganization.name : 'Select Organization';

  return (
    <Dropdown overlay={organizations} arrow={false} trigger={['click']} disabled={loading || contextLoading}>
      <Button block={true}>
        { loading || contextLoading ? <Spin />  : current }
      </Button>
    </Dropdown>
  )

};

export default OrganizationDropdown;