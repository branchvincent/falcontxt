import { gql } from '@apollo/client'

export const GetMetricsNames = gql`
  query getMetricsNames {
    metricDefinitions {
      nodes {
        name
        description
        units
      }
    }
  }
`

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
