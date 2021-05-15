import {
  configureMetricDefinition,
  fixMetricDefinitionArgs,
} from '../../models/metricDefinition'
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
    if (args?.input.metricDefinition) {
      args.input.metricDefinition = fixMetricDefinitionArgs(
        args.input.metricDefinition,
      )
    }
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
