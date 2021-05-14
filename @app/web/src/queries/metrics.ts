import { gql } from '@apollo/client'

export const GetMetricsByTime = gql`
  query getMetricsByTime($from: Datetime!, $to: Datetime!) {
    readings(filter: { time: { greaterThan: $from, lessThan: $to } }) {
      nodes {
        time
        data
      }
    }
  }
`
