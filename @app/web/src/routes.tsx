import { ComponentType, ReactNode } from 'react';
import { RouteComponentProps } from 'react-router-dom';
import { LineChartOutlined, HomeOutlined } from '@ant-design/icons';

import Metrics from './pages/Metrics';
import FacilityList from './pages/Facilities';

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

export default routes;
