import { FC } from 'react';
import { Layout, Menu } from 'antd';
import { RouteDefinition } from '../routes';
import { useHistory, useLocation, Redirect } from 'react-router-dom';
import './Header.scss';

const { Header: AntHeader } = Layout;

type HeaderProps = {
  routes: RouteDefinition[]
}

const Header: FC<HeaderProps> = ({ routes }) => {
  const history = useHistory();
  const location = useLocation();

  const currentRoute = routes.find((route) => route.path === location.pathname);
  if (!currentRoute) {
    return <Redirect to="/" />
  }

  return (
    <AntHeader>
      <div className="logo">Falcon.TXT</div>
      <Menu theme="dark" mode="horizontal" defaultSelectedKeys={[currentRoute.path]}>
        { routes.map(({ path, name }) => 
          <Menu.Item
            onClick={() => { history.push(path); } }
            key={`${path}`}>{ name }</Menu.Item>  
        )}
      </Menu>
    </AntHeader>
  );
};

export default Header;
