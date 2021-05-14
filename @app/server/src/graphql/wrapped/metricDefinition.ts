import { configureMetricDefinition } from '../../models/metricDefinition'
import { withTransaction } from '../../utils/db'
import { ResolverWrapperFn, WrapperResolver } from './index.d'

const createMetricDefinition: ResolverWrapperFn = async (
  resolve,
  source,
  args,
  context,
  resolveInfo,
) => {
  const { pgClient } = context
  const result = await withTransaction(pgClient, async () => {
    const result = await resolve(source, args, context, resolveInfo)
    await configureMetricDefinition(args?.input.metricDefinition, pgClient)
    return result
  })

  return result
}

const wrapperResolver: WrapperResolver = {
  Mutation: {
    createMetricDefinition,
  },
}

export default wrapperResolver
