/* eslint-disable */
import * as Types from '../../graphql';

import { gql } from '@apollo/client';
import * as Apollo from '@apollo/client';
const defaultOptions =  {}
export type GetMetricDefinitionsQueryVariables = Types.Exact<{ [key: string]: never; }>;


export type GetMetricDefinitionsQuery = (
  { __typename?: 'Query' }
  & { metricDefinitions?: Types.Maybe<(
    { __typename?: 'MetricDefinitionsConnection' }
    & { nodes: Array<(
      { __typename?: 'MetricDefinition' }
      & Pick<Types.MetricDefinition, 'id' | 'name' | 'query' | 'description' | 'units'>
    )> }
  )> }
);

export type CreateMetricDefinitionMutationVariables = Types.Exact<{
  metricDefinition: Types.MetricDefinitionInput;
}>;


export type CreateMetricDefinitionMutation = (
  { __typename?: 'Mutation' }
  & { createMetricDefinition?: Types.Maybe<(
    { __typename?: 'CreateMetricDefinitionPayload' }
    & { metricDefinition?: Types.Maybe<(
      { __typename?: 'MetricDefinition' }
      & Pick<Types.MetricDefinition, 'id' | 'name' | 'description' | 'query' | 'units'>
    )> }
  )> }
);

export type UpdateMetricDefinitionMutationVariables = Types.Exact<{
  id: Types.Scalars['Int'];
  metricDefinition: Types.MetricDefinitionPatch;
}>;


export type UpdateMetricDefinitionMutation = (
  { __typename?: 'Mutation' }
  & { updateMetricDefinition?: Types.Maybe<(
    { __typename?: 'UpdateMetricDefinitionPayload' }
    & { metricDefinition?: Types.Maybe<(
      { __typename?: 'MetricDefinition' }
      & Pick<Types.MetricDefinition, 'id' | 'name' | 'description' | 'query' | 'units'>
    )> }
  )> }
);


export const GetMetricDefinitionsDocument = gql`
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
    `;

/**
 * __useGetMetricDefinitionsQuery__
 *
 * To run a query within a React component, call `useGetMetricDefinitionsQuery` and pass it any options that fit your needs.
 * When your component renders, `useGetMetricDefinitionsQuery` returns an object from Apollo Client that contains loading, error, and data properties
 * you can use to render your UI.
 *
 * @param baseOptions options that will be passed into the query, supported options are listed on: https://www.apollographql.com/docs/react/api/react-hooks/#options;
 *
 * @example
 * const { data, loading, error } = useGetMetricDefinitionsQuery({
 *   variables: {
 *   },
 * });
 */
export function useGetMetricDefinitionsQuery(baseOptions?: Apollo.QueryHookOptions<GetMetricDefinitionsQuery, GetMetricDefinitionsQueryVariables>) {
        const options = {...defaultOptions, ...baseOptions}
        return Apollo.useQuery<GetMetricDefinitionsQuery, GetMetricDefinitionsQueryVariables>(GetMetricDefinitionsDocument, options);
      }
export function useGetMetricDefinitionsLazyQuery(baseOptions?: Apollo.LazyQueryHookOptions<GetMetricDefinitionsQuery, GetMetricDefinitionsQueryVariables>) {
          const options = {...defaultOptions, ...baseOptions}
          return Apollo.useLazyQuery<GetMetricDefinitionsQuery, GetMetricDefinitionsQueryVariables>(GetMetricDefinitionsDocument, options);
        }
export type GetMetricDefinitionsQueryHookResult = ReturnType<typeof useGetMetricDefinitionsQuery>;
export type GetMetricDefinitionsLazyQueryHookResult = ReturnType<typeof useGetMetricDefinitionsLazyQuery>;
export type GetMetricDefinitionsQueryResult = Apollo.QueryResult<GetMetricDefinitionsQuery, GetMetricDefinitionsQueryVariables>;
export const CreateMetricDefinitionDocument = gql`
    mutation createMetricDefinition($metricDefinition: MetricDefinitionInput!) {
  createMetricDefinition(input: {metricDefinition: $metricDefinition}) {
    metricDefinition {
      id
      name
      description
      query
      units
    }
  }
}
    `;
export type CreateMetricDefinitionMutationFn = Apollo.MutationFunction<CreateMetricDefinitionMutation, CreateMetricDefinitionMutationVariables>;

/**
 * __useCreateMetricDefinitionMutation__
 *
 * To run a mutation, you first call `useCreateMetricDefinitionMutation` within a React component and pass it any options that fit your needs.
 * When your component renders, `useCreateMetricDefinitionMutation` returns a tuple that includes:
 * - A mutate function that you can call at any time to execute the mutation
 * - An object with fields that represent the current status of the mutation's execution
 *
 * @param baseOptions options that will be passed into the mutation, supported options are listed on: https://www.apollographql.com/docs/react/api/react-hooks/#options-2;
 *
 * @example
 * const [createMetricDefinitionMutation, { data, loading, error }] = useCreateMetricDefinitionMutation({
 *   variables: {
 *      metricDefinition: // value for 'metricDefinition'
 *   },
 * });
 */
export function useCreateMetricDefinitionMutation(baseOptions?: Apollo.MutationHookOptions<CreateMetricDefinitionMutation, CreateMetricDefinitionMutationVariables>) {
        const options = {...defaultOptions, ...baseOptions}
        return Apollo.useMutation<CreateMetricDefinitionMutation, CreateMetricDefinitionMutationVariables>(CreateMetricDefinitionDocument, options);
      }
export type CreateMetricDefinitionMutationHookResult = ReturnType<typeof useCreateMetricDefinitionMutation>;
export type CreateMetricDefinitionMutationResult = Apollo.MutationResult<CreateMetricDefinitionMutation>;
export type CreateMetricDefinitionMutationOptions = Apollo.BaseMutationOptions<CreateMetricDefinitionMutation, CreateMetricDefinitionMutationVariables>;
export const UpdateMetricDefinitionDocument = gql`
    mutation updateMetricDefinition($id: Int!, $metricDefinition: MetricDefinitionPatch!) {
  updateMetricDefinition(input: {id: $id, patch: $metricDefinition}) {
    metricDefinition {
      id
      name
      description
      query
      units
    }
  }
}
    `;
export type UpdateMetricDefinitionMutationFn = Apollo.MutationFunction<UpdateMetricDefinitionMutation, UpdateMetricDefinitionMutationVariables>;

/**
 * __useUpdateMetricDefinitionMutation__
 *
 * To run a mutation, you first call `useUpdateMetricDefinitionMutation` within a React component and pass it any options that fit your needs.
 * When your component renders, `useUpdateMetricDefinitionMutation` returns a tuple that includes:
 * - A mutate function that you can call at any time to execute the mutation
 * - An object with fields that represent the current status of the mutation's execution
 *
 * @param baseOptions options that will be passed into the mutation, supported options are listed on: https://www.apollographql.com/docs/react/api/react-hooks/#options-2;
 *
 * @example
 * const [updateMetricDefinitionMutation, { data, loading, error }] = useUpdateMetricDefinitionMutation({
 *   variables: {
 *      id: // value for 'id'
 *      metricDefinition: // value for 'metricDefinition'
 *   },
 * });
 */
export function useUpdateMetricDefinitionMutation(baseOptions?: Apollo.MutationHookOptions<UpdateMetricDefinitionMutation, UpdateMetricDefinitionMutationVariables>) {
        const options = {...defaultOptions, ...baseOptions}
        return Apollo.useMutation<UpdateMetricDefinitionMutation, UpdateMetricDefinitionMutationVariables>(UpdateMetricDefinitionDocument, options);
      }
export type UpdateMetricDefinitionMutationHookResult = ReturnType<typeof useUpdateMetricDefinitionMutation>;
export type UpdateMetricDefinitionMutationResult = Apollo.MutationResult<UpdateMetricDefinitionMutation>;
export type UpdateMetricDefinitionMutationOptions = Apollo.BaseMutationOptions<UpdateMetricDefinitionMutation, UpdateMetricDefinitionMutationVariables>;