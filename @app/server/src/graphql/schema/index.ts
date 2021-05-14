import { makeExtendSchemaPlugin } from 'graphile-utils'
import { Plugin } from 'postgraphile'

import getResolvers from '../resolvers'
import getTypeDefs from '../types'

export default (): Plugin => {
  return makeExtendSchemaPlugin(() => {
    return {
      typeDefs: getTypeDefs(),
      resolvers: getResolvers(),
    }
  })
}
