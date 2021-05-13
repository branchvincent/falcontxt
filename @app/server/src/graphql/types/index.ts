import { loadFilesSync } from '@graphql-tools/load-files'
import { mergeTypeDefs } from '@graphql-tools/merge'
import { DocumentNode } from 'graphql'

const typeGlobPatterns = [__dirname]

export const registerTypes = (...globPatterns: string[]): void => {
  typeGlobPatterns.push(...globPatterns)
}

export default (): DocumentNode => {
  const staticTypes = typeGlobPatterns.reduce((types: string[], directory) => {
    types.push(...loadFilesSync(directory, { extensions: ['graphql'] }))
    return types
  }, [])
  try {
    return mergeTypeDefs(staticTypes)
  } catch (e) {
    console.error(e)
    return process.exit(1)
  }
}
