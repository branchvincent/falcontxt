import { ClientBase } from 'pg'

type AsyncExecution<T> = () => T

export async function withTransaction<T>(
  pgClient: ClientBase,
  execution: AsyncExecution<T>,
): Promise<T> {
  await pgClient.query('SAVEPOINT mutation_wrapper')
  try {
    return await execution()
  } catch (e) {
    await pgClient.query('ROLLBACK TO SAVEPOINT mutation_wrapper')
    throw e
  } finally {
    await pgClient.query('RELEASE SAVEPOINT mutation_wrapper')
  }
}
