import { FC } from 'react'
import { ApolloProvider } from '@apollo/client';
import { Layout, Empty } from 'antd';
import { BrowserRouter as Router, Route, Switch, Redirect, useRouteMatch } from 'react-router-dom';
import client from './apollo';
import SideBar from './components/SideBar';
import routes from './routes';

const { Content, Footer } = Layout;

const OrganizationRoutes : FC = () => {
  let match = useRouteMatch();
  return (
    <Switch>
      {routes.map(({ path, component }) => (
        <Route exact key={path} path={`${match.url}${path}`} component={component} />
      ))}
    </Switch>
  );
};

const EmptyScreen : FC = () => {
  return (
    <Empty style={{ marginTop: '100px' }} description="Select an organization to continue." />
  )
};

const App : FC = () => {
  return (
    <ApolloProvider client={client}>
      <Layout style={{ minHeight: '100vh' }}>
        <Router>
          <SideBar routes={routes}/>
          <Layout className="site-layout">
            <Content style={{ padding: '20px' }}>
                <Switch>
                  <Route path="/t/:organization_slug" component={OrganizationRoutes} />
                  <Route exact path="/" component={EmptyScreen} />
                  <Redirect to={"/"} />
                </Switch>
            </Content>
            <Footer style={{ fontSize: '0.8em', textAlign: 'center' }}>
                Falcon.TXT ©2021
            </Footer>
          </Layout>
        </Router>
      </Layout>
    </ApolloProvider>
  );
};

export default App;
