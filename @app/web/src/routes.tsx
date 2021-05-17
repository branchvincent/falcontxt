import {
  DashboardOutlined,
  HomeOutlined,
  LineChartOutlined,
  NumberOutlined,
} from '@ant-design/icons'
import { ComponentType, ReactNode } from 'react'
import { RouteComponentProps } from 'react-router-dom'

import MetricDefinitions from './pages/definitions'
import FacilityList from './pages/facilities'
import Metrics from './pages/metrics'
import Overview from './pages/overview'

export interface RouteDefinition {
  path: string
  name: string
  default?: boolean
  component: ComponentType<RouteComponentProps<any>> | ComponentType<any>
  icon?: ReactNode
}

const routes: RouteDefinition[] = [
  {
    path: '/overview',
    default: true,
    name: 'Overview',
    component: Overview,
    icon: <DashboardOutlined />,
  },
  {
    path: '/facilities',
    name: 'Facilities',
    component: FacilityList,
    icon: <HomeOutlined />,
  },
  {
    path: '/definitions',
    name: 'Metric Definitions',
    component: MetricDefinitions,
    icon: <NumberOutlined />,
  },
  {
    path: '/metrics',
    name: 'Metrics',
    component: Metrics,
    icon: <LineChartOutlined />,
  },
]

// eslint-disable-next-line @typescript-eslint/no-non-null-assertion
export const getDefaultRoute = (): RouteDefinition =>
  routes.find((route) => route.default)!

export default routes
