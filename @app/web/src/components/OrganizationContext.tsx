import './OrganizationContext.scss';

import { Spin } from 'antd';
import { createContext, FC, useCallback, useContext, useEffect, useState } from 'react';
import { useHistory,useLocation } from 'react-router-dom';

import { useGetOrganizationLazyQuery } from '../queries/types/organizations';
import { getDefaultRoute } from '../routes';

type OrganizationContextProps = {
  loading: boolean;
  hasOrganization: boolean;
  current?: {
    slug: string;
    name: string;
  } | null;
  changeOrganization: (slug: string) => void;
}

const initialContext : OrganizationContextProps = {
  loading: false,
  hasOrganization: false,
  changeOrganization: (slug: string) => {}
};

const OrganizationContext = createContext(initialContext);

const slugMatch = /\/t\/(?<slug>[a-zA-Z-_]+)\/?/;

const useInternalOrganizationContext = () => {
  const [fetchOrganization, { data, loading }] = useGetOrganizationLazyQuery();
  const [currentOrganization, setCurrentOrganization] = useState<string | undefined>();
  const location = useLocation();
  const history = useHistory();

  useEffect(() => {
    const matches = location.pathname.match(slugMatch);
    if (matches) {
      setCurrentOrganization(matches.groups!.slug);
    }
  }, [location]);

  useEffect(() => {
    if (currentOrganization) {
      fetchOrganization({ variables: { slug: currentOrganization }});
    }
  }, [currentOrganization, fetchOrganization]);

  useEffect(() => {
    if (loading) {
      return;
    }

    if (data?.organizationBySlug === null) {
      return history.push('/');
    }
  }, [data, loading, history]);

  const changeOrganization = useCallback((slug) => {
    const matches = location.pathname.match(slugMatch);
    if (matches) {
      const { slug: existingSlug } = matches.groups!;
      if (existingSlug === currentOrganization) {
        return;
      }

      return history.push(location.pathname.replace(`/t/${existingSlug}`, `/t/${currentOrganization}`))
    }

    const defaultRoute = getDefaultRoute();
    return history.push(`/t/${slug}${defaultRoute!.path}`);
  }, [currentOrganization, history, location]);

  return {
    loading,
    hasOrganization: slugMatch.test(location.pathname),
    current: data && data.organizationBySlug,
    changeOrganization
  }
};

const SyncOrganizationContext : FC = ({ children }) => {
  const context = useInternalOrganizationContext();
  const { hasOrganization, current } = context;
  
  return (
    <OrganizationContext.Provider value={context}>
      {
        hasOrganization && !current ? (
          <div className="loading-spin">
            <Spin size="large" />
          </div>
         ) : children
      }
    </OrganizationContext.Provider>
  )
};

export const useOrganizationContext: () => OrganizationContextProps = () => useContext(OrganizationContext);

export default SyncOrganizationContext;
