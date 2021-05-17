import { gql } from '@apollo/client'

export const GetOrganizations = gql`
  query getOrganizations {
    organizations {
      nodes {
        id
        name
        slug
        facilities {
          totalCount
        }
      }
    }
  }
`

export const GetOrganization = gql`
  query getOrganization($slug: String!) {
    organizationBySlug(slug: $slug) {
      id
      slug
      name
    }
  }
`
