import { loadFilesSync } from '@graphql-tools/load-files'
import { mergeResolvers } from '@graphql-tools/merge'

export default () => {
  const resolversArray = loadFilesSync(__dirname, {
    ignoreIndex: true,
    extensions: ['ts'],
  })
  return mergeResolvers([...resolversArray])
}
