import { gql } from '@apollo/client';

export const GetFacilitiesByOrganization = gql`
  query getFacilitiesByOrganization($slug: String!) {
    organizationBySlug(slug: $slug) {
      facilities {
        nodes {
          slug
          name
        }
      }
    }
  }
`;