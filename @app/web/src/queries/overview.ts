import { gql } from '@apollo/client'

export const GetFacilityRankings = gql`
  query getFacilityRankings($metric: String!, $tags: [String]) {
    facilityRankings(metric: $metric, tags: $tags) {
      nodes {
        facility {
          slug
        }
        rank
        tags
        value
      }
    }
  }
`
