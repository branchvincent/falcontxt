import { gql } from '@apollo/client'

export const GetFacilitiesByOrganization = gql`
  query getFacilitiesByOrganization($slug: String!) {
    organizationBySlug(slug: $slug) {
      facilities {
        nodes {
          id
          slug
          name
        }
      }
    }
  }
`

export const CreateFacility = gql`
  mutation createFacility($facility: FacilityInput!) {
    createFacility(input: { facility: $facility }) {
      facility {
        id
        name
        slug
      }
    }
  }
`

export const UpdateFacility = gql`
  mutation updateFacility($id: Int!, $facility: FacilityPatch!) {
    updateFacility(input: { id: $id, patch: $facility }) {
      facility {
        id
        name
        slug
      }
    }
  }
`
