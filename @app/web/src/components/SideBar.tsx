import './SideBar.scss'

import { Layout, Menu } from 'antd'
import cn from 'classnames'
import { FC, useEffect, useState } from 'react'
import { useHistory, useLocation } from 'react-router-dom'

import { useOrganizationContext } from '../components/OrganizationContext'
import { getDefaultRoute, RouteDefinition } from '../routes'
import OrganizationDropdown from './OrganizationDropdown'

const { Sider } = Layout

type SideBarProps = {
  routes: RouteDefinition[]
}

const SideBar: FC<SideBarProps> = ({ routes }) => {
  const { current } = useOrganizationContext()
  const [selectedKey, setSelectedKey] = useState<string>()
  const [collapsed, setCollapsed] = useState<boolean>()
  const history = useHistory()
  const location = useLocation()

  useEffect(() => {
    const currentRoute = routes.find((route) =>
      location.pathname.includes(route.path),
    )
    setSelectedKey(currentRoute?.path || undefined)
  }, [location.pathname, setSelectedKey, routes])

  const homeRoute = current
    ? `/t/${current.slug}${getDefaultRoute().path}`
    : '/'

  return (
    <Sider
      collapsible
      collapsed={collapsed}
      onCollapse={() => setCollapsed(!collapsed)}
    >
      <div
        style={{ cursor: 'pointer' }}
        onClick={() => history.push(homeRoute)}
        className={cn('logo', collapsed && 'collapsed')}
      >
        {collapsed ? 'F.TXT' : 'Falcon.TXT'}
      </div>
      <OrganizationDropdown />
      <Menu
        theme="dark"
        selectedKeys={selectedKey ? [selectedKey] : []}
        mode="inline"
      >
        {routes.map(({ path, name, icon: Icon }) => (
          <Menu.Item
            disabled={!current}
            onClick={() => {
              current && history.push(`/t/${current!.slug}${path}`)
            }}
            key={`${path}`}
            icon={Icon}
          >
            {name}
          </Menu.Item>
        ))}
      </Menu>
    </Sider>
  )
}

export default SideBar
