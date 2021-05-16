import {
  HomeOutlined,
  LineChartOutlined,
  NumberOutlined,
} from '@ant-design/icons'
import { ComponentType, ReactNode } from 'react'
import { RouteComponentProps } from 'react-router-dom'

import MetricDefitinions from './pages/definitions'
import FacilityList from './pages/facilities'
import Metrics from './pages/metrics'

export interface RouteDefinition {
  path: string
  name: string
  default?: boolean
  component: ComponentType<RouteComponentProps<any>> | ComponentType<any>
  icon?: ReactNode
}

const routes: RouteDefinition[] = [
  {
    path: '/facilities',
    default: true,
    name: 'Facilities',
    component: FacilityList,
    icon: <HomeOutlined />,
  },
  {
    path: '/metrics',
    name: 'Metrics',
    component: Metrics,
    icon: <LineChartOutlined />,
  },
  {
    path: '/definitions',
    name: 'Metric Definitions',
    component: MetricDefitinions,
    icon: <NumberOutlined />,
  },
]

// eslint-disable-next-line @typescript-eslint/no-non-null-assertion
export const getDefaultRoute = (): RouteDefinition =>
  routes.find((route) => route.default)!

export default routes
