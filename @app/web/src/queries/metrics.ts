import { gql } from '@apollo/client'

export const GetFacilityMetrics = gql`
  query getFacilityMetrics($name: String!, $from: Datetime!, $to: Datetime!) {
    facilities {
      nodes {
        slug
        metrics(
          name: $name
          filter: { time: { greaterThan: $from, lessThan: $to } }
        ) {
          nodes {
            time
            avg
          }
        }
      }
    }
  }
`
