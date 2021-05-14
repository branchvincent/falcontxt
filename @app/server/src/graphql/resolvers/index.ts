import { loadFilesSync } from '@graphql-tools/load-files'
import { mergeResolvers } from '@graphql-tools/merge'
import { Resolvers } from 'postgraphile'

export default (): Resolvers => {
  const resolversArray = loadFilesSync(__dirname, {
    ignoreIndex: true,
    extensions: ['ts'],
  })
  return mergeResolvers([...resolversArray])
}
