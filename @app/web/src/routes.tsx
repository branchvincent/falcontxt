import { HomeOutlined,LineChartOutlined } from '@ant-design/icons';
import { ComponentType, ReactNode } from 'react';
import { RouteComponentProps } from 'react-router-dom';

import FacilityList from './pages/Facilities';
import Metrics from './pages/Metrics';

export interface RouteDefinition  {
  path: string;
  name: string;
  default?: boolean;
  component: ComponentType<RouteComponentProps<any>> | ComponentType<any>;
  icon?: ReactNode
}

const routes : RouteDefinition[] = [
  {
    path: '/facilities',
    default: true,
    name: 'Facilities',
    component: FacilityList,
    icon: <HomeOutlined />
  },
  {
    path: '/metrics',
    name: 'Metrics',
    component: Metrics,
    icon: <LineChartOutlined />
  }
];

export const getDefaultRoute = () => routes.find((route) => route.default)!;

export default routes;
