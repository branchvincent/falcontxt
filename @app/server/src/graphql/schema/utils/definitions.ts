import {
  DefinitionNode,
  DirectiveDefinitionNode,
  isTypeDefinitionNode,
  isTypeExtensionNode,
  Kind,
  SchemaDefinitionNode,
  TypeDefinitionNode,
  TypeExtensionNode,
  TypeSystemDefinitionNode,
  TypeSystemExtensionNode,
} from 'graphql/language'

export const OperationType: { [name: string]: string } = {
  Query: 'Query',
  Mutation: 'Mutation',
  Subscription: 'Subscription',
}

export interface DeconstructedDocumentNode {
  typeDefinitionMap: { [name: string]: TypeDefinitionNode }
  typeExtensionDefinitionMap: { [name: string]: TypeExtensionNode[] }
  directiveDefinitionMap: { [name: string]: DirectiveDefinitionNode }
  operationTypeMap: { [name: string]: TypeDefinitionNode }
  schemaTypeDefinition?: SchemaDefinitionNode | undefined
}

/**
 * Groups the defintions into 5 categories for easier transformation:
 *  - typeDefinitionMap: Actual types
 *  - typeExtensionDefinitionMap: Extension types
 *  - directiveDefinitionMap: Directives
 *  - operationTypeMap: GraphQL operations (Query/Mutation/Subscription)
 *  - schemaTypeDefinition: The schema type
 *
 * @param {*} definitions the type definitions
 */
export const mapTypeDefinitions = (
  definitions: DefinitionNode[],
): DeconstructedDocumentNode => {
  const typeDefinitionMap: { [name: string]: TypeDefinitionNode } = {}
  const typeExtensionDefinitionMap: { [name: string]: TypeExtensionNode[] } = {}
  const directiveDefinitionMap: { [name: string]: DirectiveDefinitionNode } = {}
  const operationTypeMap: { [name: string]: TypeDefinitionNode } = {}
  let schemaTypeDefinition: SchemaDefinitionNode | undefined = undefined
  definitions.forEach((definition) => {
    if (definition.kind === Kind.SCHEMA_DEFINITION) {
      schemaTypeDefinition = definition
    } else if (isTypeDefinitionNode(definition)) {
      const {
        name: { value: name },
      } = definition
      if (OperationType[name]) {
        operationTypeMap[name] = definition
      } else {
        typeDefinitionMap[name] = definition
      }
    } else if (isTypeExtensionNode(definition)) {
      const {
        name: { value: name },
      } = definition
      typeExtensionDefinitionMap[name] = [
        ...(typeExtensionDefinitionMap[name] || []),
        definition,
      ]
    } else if (definition.kind === Kind.DIRECTIVE_DEFINITION) {
      const {
        name: { value: name },
      } = definition
      directiveDefinitionMap[name] = definition
    }
  })

  return {
    typeDefinitionMap,
    typeExtensionDefinitionMap,
    directiveDefinitionMap,
    operationTypeMap,
    schemaTypeDefinition,
  }
}

/**
 * Merges the categorized definitions back into a single GraphQL document
 *
 * @param {*} definitionMaps The categorized definitions
 */
export const mergeDefinitionMaps = ({
  typeDefinitionMap,
  typeExtensionDefinitionMap,
  directiveDefinitionMap,
  operationTypeMap,
  schemaTypeDefinition,
}: DeconstructedDocumentNode): (
  | TypeSystemDefinitionNode
  | TypeSystemExtensionNode
)[] => {
  let typeExtensions: TypeExtensionNode[] = []
  if (Object.keys(typeExtensionDefinitionMap).length > 0) {
    typeExtensions = Object.values(typeExtensionDefinitionMap).reduce(
      (acc, extensionValue) => [...acc, ...extensionValue],
      [],
    )
  }

  const definitions: (TypeSystemDefinitionNode | TypeSystemExtensionNode)[] = [
    ...Object.values(typeDefinitionMap).map(
      (def) => def as TypeSystemDefinitionNode,
    ),
    ...typeExtensions,
    ...Object.values(directiveDefinitionMap),
    ...Object.values(operationTypeMap),
  ]
  if (schemaTypeDefinition) {
    definitions.push(schemaTypeDefinition)
  }

  return definitions
}
