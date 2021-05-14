/* eslint-disable */
import * as Types from '../../graphql';

import { gql } from '@apollo/client';
import * as Apollo from '@apollo/client';
const defaultOptions =  {}
export type GetFacilitiesByOrganizationQueryVariables = Types.Exact<{
  slug: Types.Scalars['String'];
}>;


export type GetFacilitiesByOrganizationQuery = (
  { __typename?: 'Query' }
  & { organizationBySlug?: Types.Maybe<(
    { __typename?: 'Organization' }
    & { facilities: (
      { __typename?: 'FacilitiesConnection' }
      & { nodes: Array<(
        { __typename?: 'Facility' }
        & Pick<Types.Facility, 'slug' | 'name'>
      )> }
    ) }
  )> }
);


export const GetFacilitiesByOrganizationDocument = gql`
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

/**
 * __useGetFacilitiesByOrganizationQuery__
 *
 * To run a query within a React component, call `useGetFacilitiesByOrganizationQuery` and pass it any options that fit your needs.
 * When your component renders, `useGetFacilitiesByOrganizationQuery` returns an object from Apollo Client that contains loading, error, and data properties
 * you can use to render your UI.
 *
 * @param baseOptions options that will be passed into the query, supported options are listed on: https://www.apollographql.com/docs/react/api/react-hooks/#options;
 *
 * @example
 * const { data, loading, error } = useGetFacilitiesByOrganizationQuery({
 *   variables: {
 *      slug: // value for 'slug'
 *   },
 * });
 */
export function useGetFacilitiesByOrganizationQuery(baseOptions: Apollo.QueryHookOptions<GetFacilitiesByOrganizationQuery, GetFacilitiesByOrganizationQueryVariables>) {
        const options = {...defaultOptions, ...baseOptions}
        return Apollo.useQuery<GetFacilitiesByOrganizationQuery, GetFacilitiesByOrganizationQueryVariables>(GetFacilitiesByOrganizationDocument, options);
      }
export function useGetFacilitiesByOrganizationLazyQuery(baseOptions?: Apollo.LazyQueryHookOptions<GetFacilitiesByOrganizationQuery, GetFacilitiesByOrganizationQueryVariables>) {
          const options = {...defaultOptions, ...baseOptions}
          return Apollo.useLazyQuery<GetFacilitiesByOrganizationQuery, GetFacilitiesByOrganizationQueryVariables>(GetFacilitiesByOrganizationDocument, options);
        }
export type GetFacilitiesByOrganizationQueryHookResult = ReturnType<typeof useGetFacilitiesByOrganizationQuery>;
export type GetFacilitiesByOrganizationLazyQueryHookResult = ReturnType<typeof useGetFacilitiesByOrganizationLazyQuery>;
export type GetFacilitiesByOrganizationQueryResult = Apollo.QueryResult<GetFacilitiesByOrganizationQuery, GetFacilitiesByOrganizationQueryVariables>;