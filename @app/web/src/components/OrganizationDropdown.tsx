import { Button, Dropdown, Menu, Spin } from 'antd'
import { FC } from 'react'

import { useOrganizationContext } from '../components/OrganizationContext'
import { useGetOrganizationsQuery } from '../queries/types/organizations'

const OrganizationDropdown: FC = () => {
  const { current } = useOrganizationContext()
  const { changeOrganization } = useOrganizationContext()
  const { data, loading } = useGetOrganizationsQuery()

  const organizations = (
    <Menu>
      {data?.organizations?.nodes.map((organization) => (
        <Menu.Item
          key={`${organization.slug}`}
          onClick={() => changeOrganization(organization.slug)}
        >
          {organization.name}
        </Menu.Item>
      ))}
    </Menu>
  )

  return (
    <Dropdown
      overlay={organizations}
      arrow={false}
      trigger={['click']}
      disabled={loading}
    >
      <Button block={true}>
        {loading ? <Spin /> : current?.name || 'Select Organization'}
      </Button>
    </Dropdown>
  )
}

export default OrganizationDropdown
