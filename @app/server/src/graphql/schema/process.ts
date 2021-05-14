import { ResolversDefinition } from '@graphql-tools/merge'
import { DefinitionNode, DocumentNode } from 'graphql'

import applyMappers from './apply'
import { buildDocument } from './utils/ast'
import { mapTypeDefinitions, mergeDefinitionMaps } from './utils/definitions'

/**
 * Entrypoint to pre-process our AST type definitions to mutate/extract aspects of the schema
 * @param {*} typeDefs
 * @param {*} resolvers
 */
function parseTypeDefs<TContext, T extends ResolversDefinition<TContext>>(
  typeDefs: DocumentNode,
  resolvers: ResolversDefinition<T>[],
): {
  typeDefs: DocumentNode
  resolvers: ResolversDefinition<T>[]
} {
  const { definitions } = typeDefs
  const mutatedDefinitions: DefinitionNode[] = [...definitions]

  // Extract
  const mappedAst = mapTypeDefinitions(mutatedDefinitions)

  // Middleware logic
  applyMappers({ ...mappedAst, resolvers })

  // Merge
  const newDefinitions = mergeDefinitionMaps(mappedAst)

  return {
    typeDefs: buildDocument({ definitions: newDefinitions }),
    resolvers,
  }
}

export default parseTypeDefs
