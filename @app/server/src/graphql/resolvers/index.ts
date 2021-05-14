import { loadFilesSync } from '@graphql-tools/load-files'
import { mergeResolvers, ResolversDefinition } from '@graphql-tools/merge'

function loadResolvers<
  TContext,
  T extends ResolversDefinition<TContext>,
>(): ResolversDefinition<T> {
  const resolversArray = loadFilesSync(__dirname, {
    ignoreIndex: true,
    extensions: ['ts'],
  })
  return mergeResolvers([...resolversArray])
}

export default loadResolvers
