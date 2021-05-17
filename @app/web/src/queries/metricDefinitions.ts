import { gql } from '@apollo/client'

export const GetMetricDefinitions = gql`
  query getMetricDefinitions {
    metricDefinitions {
      nodes {
        id
        name
        query
        description
        units
      }
    }
  }
`

export const CreateMetricDefinition = gql`
  mutation createMetricDefinition($metricDefinition: MetricDefinitionInput!) {
    createMetricDefinition(input: { metricDefinition: $metricDefinition }) {
      metricDefinition {
        id
        name
        description
        query
        units
      }
    }
  }
`

export const UpdateMetricDefinition = gql`
  mutation updateMetricDefinition(
    $id: Int!
    $metricDefinition: MetricDefinitionPatch!
  ) {
    updateMetricDefinition(input: { id: $id, patch: $metricDefinition }) {
      metricDefinition {
        id
        name
        description
        query
        units
      }
    }
  }
`
