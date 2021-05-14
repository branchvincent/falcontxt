import {
  ArgumentNode,
  DefinitionNode,
  DirectiveNode,
  DocumentNode,
  FieldDefinitionNode,
  InputValueDefinitionNode,
  Kind,
  ListTypeNode,
  NamedTypeNode,
  NameNode,
  NonNullTypeNode,
  ObjectTypeDefinitionNode,
  StringValueNode,
  TypeNode,
  ValueNode,
} from 'graphql/language'

import { TypeWrapperMap, TypeWrappers } from './fields'

export const buildDocument = ({
  definitions = [],
}: {
  definitions: DefinitionNode[]
}): DocumentNode => ({
  kind: Kind.DOCUMENT,
  definitions,
})

export const buildInputField = ({
  name,
  type,
  directives = [],
  defaultValue,
  description,
}: {
  name: NameNode
  type: TypeNode
  directives: DirectiveNode[]
  defaultValue: ValueNode
  description: StringValueNode
}): InputValueDefinitionNode => ({
  kind: Kind.INPUT_VALUE_DEFINITION,
  name,
  type,
  directives,
  description,
  defaultValue,
})

export const buildField = ({
  name,
  type,
  args = [],
  directives = [],
  description,
}: {
  name: NameNode
  type: TypeNode
  args: InputValueDefinitionNode[]
  directives: DirectiveNode[]
  description: StringValueNode
}): FieldDefinitionNode => ({
  kind: Kind.FIELD_DEFINITION,
  name,
  type,
  arguments: args,
  directives,
  description,
})

export const buildArgument = ({
  name,
  value,
}: {
  name: NameNode
  value: ValueNode
}): ArgumentNode => ({
  kind: Kind.ARGUMENT,
  name,
  value,
})

export const buildDirective = ({
  name,
  args,
}: {
  name: NameNode
  args: ArgumentNode[]
}): DirectiveNode => ({
  kind: Kind.DIRECTIVE,
  name,
  arguments: args,
})

export const buildName = ({ name }: { name: string }): NameNode => ({
  kind: Kind.NAME,
  value: name,
})

export const buildObjectType = ({
  name,
  interfaces = [],
  fields = [],
  directives = [],
  description,
}: {
  name: NameNode
  interfaces: NamedTypeNode[]
  fields: FieldDefinitionNode[]
  directives: DirectiveNode[]
  description: StringValueNode
}): ObjectTypeDefinitionNode => ({
  kind: Kind.OBJECT_TYPE_DEFINITION,
  interfaces,
  name,
  fields,
  directives,
  description,
})

export const buildDescription = ({
  value,
  block = false,
}: {
  value: string
  block: boolean
}): StringValueNode => ({
  kind: Kind.STRING,
  value,
  block,
})

export const buildNamedType = ({
  name,
  wrappers = {},
}: {
  name: string
  wrappers: TypeWrapperMap
}): TypeNode => {
  let type: TypeNode = {
    kind: Kind.NAMED_TYPE,
    name: buildName({ name }),
  }
  if (wrappers[TypeWrappers.NON_NULL_NAMED_TYPE]) {
    type = {
      kind: Kind.NON_NULL_TYPE,
      type: type as NamedTypeNode,
    } as NonNullTypeNode
  }
  if (wrappers[TypeWrappers.LIST_TYPE]) {
    type = {
      kind: Kind.LIST_TYPE,
      type: type,
    } as ListTypeNode
  }
  if (wrappers[TypeWrappers.NON_NULL_LIST_TYPE]) {
    type = {
      kind: Kind.NON_NULL_TYPE,
      type,
    } as NonNullTypeNode
  }
  return type
}
