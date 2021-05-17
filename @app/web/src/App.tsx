import { ApolloProvider } from '@apollo/client'
import { Empty, Layout, Spin } from 'antd'
import { FC } from 'react'
import {
  BrowserRouter as Router,
  Redirect,
  Route,
  Switch,
  useHistory,
  useRouteMatch,
} from 'react-router-dom'

import client from './apollo'
import SyncOrganizationContext, {
  useOrganizationContext,
} from './components/OrganizationContext'
import SideBar from './components/SideBar'
import routes, { getDefaultRoute } from './routes'

const { Content, Footer } = Layout

const OrganizationRoutes: FC = () => {
  const { current } = useOrganizationContext()
  const match = useRouteMatch()
  return (
    <>
      {!current ? (
        <div className="loading-spin">
          <Spin />
        </div>
      ) : (
        <Switch>
          {routes.map(({ path, component }) => (
            <Route
              exact
              key={path}
              path={`${match.url}${path}`}
              component={component}
            />
          ))}
        </Switch>
      )}
    </>
  )
}

const EmptyScreen: FC = () => {
  const { current } = useOrganizationContext()
  const history = useHistory()
  if (current) {
    history.push(`/t/${current.slug}${getDefaultRoute().path}`)
    return null
  }

  return (
    <Empty
      style={{ marginTop: '100px' }}
      description="Select an organization to continue."
    />
  )
}

const App: FC = () => {
  return (
    <ApolloProvider client={client}>
      <Layout style={{ minHeight: '100vh' }}>
        <Router>
          <SyncOrganizationContext>
            <SideBar routes={routes} />
            <Layout className="site-layout">
              <Content style={{ padding: '20px' }}>
                <Switch>
                  <Route
                    path="/t/:organization_slug"
                    component={OrganizationRoutes}
                  />
                  <Route exact path="/" component={EmptyScreen} />
                  <Redirect to={'/'} />
                </Switch>
              </Content>
              <Footer style={{ fontSize: '0.8em', textAlign: 'center' }}>
                Falcon.TXT ©2021
              </Footer>
            </Layout>
          </SyncOrganizationContext>
        </Router>
      </Layout>
    </ApolloProvider>
  )
}

export default App
