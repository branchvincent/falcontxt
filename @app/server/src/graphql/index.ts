import { makeExtendSchemaPlugin } from 'graphile-utils'

import getResolvers from './resolvers'
import getTypeDefs from './types'

const MyPlugin = makeExtendSchemaPlugin(() => {
  return {
    typeDefs: getTypeDefs(),
    resolvers: getResolvers(),
  }
})

export default MyPlugin
