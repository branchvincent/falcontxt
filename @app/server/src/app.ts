import cors from 'cors'
import express from 'express'
import expressPlayground from 'graphql-playground-middleware-express'
import { postgraphile } from 'postgraphile'

import { database, options, schemas } from './config'

const app = express()

app.use(cors())
app.use(postgraphile(database, schemas, options))
app.get('/playground', expressPlayground({ endpoint: '/graphql' }))

export default app
