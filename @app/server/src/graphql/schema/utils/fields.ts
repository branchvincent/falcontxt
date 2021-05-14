import { ArgumentNode, TypeDefinitionNode } from 'graphql'
import {
  DirectiveNode,
  FieldDefinitionNode,
  ObjectTypeDefinitionNode,
  ValueNode,
} from 'graphql/language'

type TypeWrapper = string

export type TypeWrapperMap = {
  [name: string]: boolean
}

export const TypeWrappers = {
  NAME: 'name',
  NON_NULL_NAMED_TYPE: 'isNonNullNamedType',
  LIST_TYPE: 'isListType',
  NON_NULL_LIST_TYPE: 'isNonNullListType',
}

const defaultWrappers: TypeWrapperMap = {
  [TypeWrappers.LIST_TYPE]: false,
  [TypeWrappers.NON_NULL_NAMED_TYPE]: false,
  [TypeWrappers.NON_NULL_LIST_TYPE]: false,
}

export const isOfKind = (
  typeDefinition: TypeDefinitionNode,
  ...kinds: string[]
): boolean => !!kinds.find((k) => k === typeDefinition.kind)

export const normalizeArguments = (
  args: ArgumentNode[],
): { [name: string]: ValueNode } =>
  args.reduce<{ [name: string]: ValueNode }>((acc, arg) => {
    acc[arg.name.value] = arg.value
    return acc
  }, {})

export const getField = (
  typeDefinition: ObjectTypeDefinitionNode,
  fieldName: string,
): FieldDefinitionNode | undefined =>
  (typeDefinition.fields || []).find((d) => d.name.value === fieldName)

export const getDirective = (
  typeDefinition: TypeDefinitionNode,
  directiveName: string,
): DirectiveNode | undefined =>
  (typeDefinition.directives || []).find((d) => d.name.value === directiveName)

export const withWrappers = (...wrappers: TypeWrapper[]): TypeWrapperMap =>
  (wrappers || []).reduce(
    (acc, wrapper) => ({ ...acc, [wrapper]: true }),
    defaultWrappers,
  )
