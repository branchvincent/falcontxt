import { FC, useState, useEffect } from 'react';
import { Menu, Layout } from 'antd';
import cn from 'classnames';
import { RouteDefinition } from '../routes';
import { useHistory, useLocation } from 'react-router-dom';
import OrganizationDropdown from './OrganizationDropdown';
import useOrganizationContext from '../hooks/useOrganizationContext';
import './SideBar.scss';

const { Sider } = Layout;

type SideBarProps = {
  routes: RouteDefinition[]
}

const SideBar : FC<SideBarProps> = ({ routes }) => {
  const { currentOrganization, loading } = useOrganizationContext();
  const [selectedKey, setSelectedKey] = useState<string>();
  const [collapsed, setCollapsed] = useState<boolean>();
  const history = useHistory();
  const location = useLocation();

  useEffect(() => {
    const currentRoute = routes.find((route) => location.pathname.includes(route.path));
    setSelectedKey(currentRoute?.path || undefined);
  }, [location.pathname, setSelectedKey, routes])

  return (
    <Sider collapsible collapsed={collapsed} onCollapse={() => setCollapsed(!collapsed)}>
      <div style={{ cursor: 'pointer' }} onClick={() => history.push('/')} className={cn('logo', collapsed && 'collapsed')}>{ collapsed ? 'F.TXT' : 'Falcon.TXT' }</div>
      <OrganizationDropdown />
      <Menu theme="dark" selectedKeys={selectedKey ? [selectedKey] : []} mode="inline">
        { routes.map(({ path, name, icon: Icon }) => 
          <Menu.Item
            disabled={loading || !currentOrganization}
            onClick={() => { currentOrganization && history.push(`/t/${currentOrganization!.slug}${path}`); } }
            key={`${path}`}
            icon={Icon}
            >{ name }</Menu.Item>  
        )}
      </Menu>
    </Sider>
  )
};

export default SideBar;