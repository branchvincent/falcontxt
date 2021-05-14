import { makeExtendSchemaPlugin, makeWrapResolversPlugin } from 'graphile-utils'

import getResolvers from './resolvers'
import getTypeDefs from './types'
import getWrappedResolvers from './wrapped'

export const extendSchema = makeExtendSchemaPlugin(() => {
  return {
    typeDefs: getTypeDefs(),
    resolvers: getResolvers(),
  }
})

export const extendResolvers = makeWrapResolversPlugin(
  getWrappedResolvers().reduce(
    (acc, resolver) => ({ ...acc, ...resolver }),
    {},
  ),
)
