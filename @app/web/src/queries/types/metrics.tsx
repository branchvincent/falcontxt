/* eslint-disable */
import * as Types from '../../graphql';

import { gql } from '@apollo/client';
import * as Apollo from '@apollo/client';
const defaultOptions =  {}
export type GetMetricsByTimeQueryVariables = Types.Exact<{
  from: Types.Scalars['Datetime'];
  to: Types.Scalars['Datetime'];
}>;


export type GetMetricsByTimeQuery = (
  { __typename?: 'Query' }
  & { readings?: Types.Maybe<(
    { __typename?: 'ReadingsConnection' }
    & { nodes: Array<(
      { __typename?: 'Reading' }
      & Pick<Types.Reading, 'time' | 'data'>
    )> }
  )> }
);


export const GetMetricsByTimeDocument = gql`
    query getMetricsByTime($from: Datetime!, $to: Datetime!) {
  readings(filter: {time: {greaterThan: $from, lessThan: $to}}) {
    nodes {
      time
      data
    }
  }
}
    `;

/**
 * __useGetMetricsByTimeQuery__
 *
 * To run a query within a React component, call `useGetMetricsByTimeQuery` and pass it any options that fit your needs.
 * When your component renders, `useGetMetricsByTimeQuery` returns an object from Apollo Client that contains loading, error, and data properties
 * you can use to render your UI.
 *
 * @param baseOptions options that will be passed into the query, supported options are listed on: https://www.apollographql.com/docs/react/api/react-hooks/#options;
 *
 * @example
 * const { data, loading, error } = useGetMetricsByTimeQuery({
 *   variables: {
 *      from: // value for 'from'
 *      to: // value for 'to'
 *   },
 * });
 */
export function useGetMetricsByTimeQuery(baseOptions: Apollo.QueryHookOptions<GetMetricsByTimeQuery, GetMetricsByTimeQueryVariables>) {
        const options = {...defaultOptions, ...baseOptions}
        return Apollo.useQuery<GetMetricsByTimeQuery, GetMetricsByTimeQueryVariables>(GetMetricsByTimeDocument, options);
      }
export function useGetMetricsByTimeLazyQuery(baseOptions?: Apollo.LazyQueryHookOptions<GetMetricsByTimeQuery, GetMetricsByTimeQueryVariables>) {
          const options = {...defaultOptions, ...baseOptions}
          return Apollo.useLazyQuery<GetMetricsByTimeQuery, GetMetricsByTimeQueryVariables>(GetMetricsByTimeDocument, options);
        }
export type GetMetricsByTimeQueryHookResult = ReturnType<typeof useGetMetricsByTimeQuery>;
export type GetMetricsByTimeLazyQueryHookResult = ReturnType<typeof useGetMetricsByTimeLazyQuery>;
export type GetMetricsByTimeQueryResult = Apollo.QueryResult<GetMetricsByTimeQuery, GetMetricsByTimeQueryVariables>;