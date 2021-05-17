import { gql } from '@apollo/client'

export const GetFacilityRankings = gql`
  query getFacilityRankings($metric: String!, $tags: [String]) {
    facilityRankings(metric: $metric, tags: $tags) {
      nodes {
        id
        rank
        tags
        value
      }
    }
  }
`
