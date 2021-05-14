import { ResolversDefinition } from '@graphql-tools/merge'

import { DeconstructedDocumentNode } from '../utils/definitions'

type ASTSchemaMapper<TContext, T extends ResolversDefinition<TContext>> = (
  schema: ASTMapProps<TContext, T>,
) => void

interface ASTMapProps<TContext, T extends ResolversDefinition<TContext>>
  extends DeconstructedDocumentNode {
  resolvers: ResolversDefinition<T>[]
}

const mappers: ASTSchemaMapper<never, never>[] = []

function map<TContext, T extends ResolversDefinition<TContext>>(
  astSchema: ASTMapProps<TContext, T>,
): void {
  mappers.forEach((m) => m(astSchema))
}

export default map
