import { makeExtendSchemaPlugin, makeWrapResolversPlugin } from 'graphile-utils'

import getResolvers from './resolvers'
import getTypeDefs from './types'

export const extendSchema = makeExtendSchemaPlugin(() => {
  return {
    typeDefs: getTypeDefs(),
    resolvers: getResolvers(),
  }
})

export const extendResolvers = makeWrapResolversPlugin({
  Mutation: {
    createMetricDefinition: async (
      resolve,
      source,
      args,
      context,
      resolveInfo,
    ) => {
      const result = await resolve(source, args, context, resolveInfo)
      console.log(result)
      return result
    },
  },
})
