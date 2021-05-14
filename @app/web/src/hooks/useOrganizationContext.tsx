import { useCallback, useEffect, useState } from 'react';
import { useLocation, useHistory } from 'react-router-dom';
import routes from '../routes';
import { useGetOrganizationLazyQuery } from '../queries/types/organizations';

const slugMatch = /\/t\/(?<slug>[a-zA-Z-_]+)\/?/;

const useOrganizationContext = () => {
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

    const defaultRoute = routes.find((route) => route.default)!;
    return history.push(`/t/${slug}${defaultRoute!.path}`);
  }, [currentOrganization, history, location]);

  return {
    loading,
    currentOrganization: data && data.organizationBySlug,
    changeOrganization
  }
};

export default useOrganizationContext;