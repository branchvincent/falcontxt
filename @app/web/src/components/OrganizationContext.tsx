import './OrganizationContext.scss'

import { Space, Typography } from 'antd'
import {
  createContext,
  FC,
  useCallback,
  useContext,
  useEffect,
  useState,
} from 'react'
import { useHistory, useLocation } from 'react-router-dom'

import { Organization } from '../graphql'
import { useGetOrganizationLazyQuery } from '../queries/types/organizations'
import { getDefaultRoute } from '../routes'

const { Text } = Typography

type OrganizationContextProps = {
  loading: boolean
  hasOrganization: boolean
  current?: Organization
  changeOrganization: (slug: string) => void
}

const initialContext: OrganizationContextProps = {
  loading: false,
  hasOrganization: false,
  changeOrganization: () => {},
}

const OrganizationContext = createContext(initialContext)

const slugMatch = /\/t\/(?<slug>[a-zA-Z-_]+)\/?/

const useInternalOrganizationContext = () => {
  const [fetchOrganization, { data, loading }] = useGetOrganizationLazyQuery()
  const [currentOrganization, setCurrentOrganization] =
    useState<string | undefined>()
  const location = useLocation()
  const history = useHistory()

  useEffect(() => {
    const matches = location.pathname.match(slugMatch)
    if (matches && matches.groups) {
      setCurrentOrganization(matches.groups.slug)
    }
  }, [location])

  useEffect(() => {
    if (currentOrganization) {
      fetchOrganization({ variables: { slug: currentOrganization } })
    }
  }, [currentOrganization, fetchOrganization])

  useEffect(() => {
    if (loading) {
      return
    }

    if (data?.organizationBySlug === null) {
      return history.push('/')
    }
  }, [data, loading, history])

  const changeOrganization = useCallback(
    (slug) => {
      const matches = location.pathname.match(slugMatch)
      if (matches && matches.groups) {
        const { slug: existingSlug } = matches.groups
        if (existingSlug === currentOrganization) {
          return
        }

        return history.push(
          location.pathname.replace(
            `/t/${existingSlug}`,
            `/t/${currentOrganization}`,
          ),
        )
      }

      const defaultRoute = getDefaultRoute()
      return history.push(`/t/${slug}${defaultRoute.path}`)
    },
    [currentOrganization, history, location],
  )

  return {
    loading,
    hasOrganization: slugMatch.test(location.pathname),
    current: data && (data.organizationBySlug as Organization),
    changeOrganization,
  }
}

const SyncOrganizationContext: FC = ({ children }) => {
  const context = useInternalOrganizationContext()
  const [fakeLoading, setFakeLoading] = useState(true)

  useEffect(() => {
    setTimeout(() => {
      setFakeLoading(false)
    }, 5000)
  }, [setFakeLoading])

  return (
    <OrganizationContext.Provider value={context}>
      {fakeLoading ? (
        <div className="loading-spin" onClick={() => setFakeLoading(false)}>
          <Space direction="vertical" align="center">
            <img src={`${process.env.PUBLIC_URL}/FalconAirKick.gif`} />
            <Text strong style={{ fontFamily: 'monospace' }}>
              falcon.txt loading...
            </Text>
          </Space>
        </div>
      ) : (
        children
      )}
    </OrganizationContext.Provider>
  )
}

export const useOrganizationContext: () => OrganizationContextProps = () =>
  useContext(OrganizationContext)

export default SyncOrganizationContext
