import { GraphQLFieldResolver, GraphQLResolveInfo } from 'graphql'

export type ResolverWrapperFn<
  TSource = any,
  TContext = any,
  TArgs = {
    [argName: string]: any
  },
> = (
  resolve: GraphQLFieldResolver<TSource, TContext, TArgs>,
  source: TSource,
  args: TArgs,
  context: TContext,
  resolveInfo: GraphQLResolveInfo,
) => any

export type WrapperResolver = {
  [name: string]: { [fieldName: string]: ResolverWrapperFn }
}
