import cors from 'cors'
import express from 'express'
import { postgraphile } from 'postgraphile'

import { database, options, schemas } from './config'

const app = express()

app.use(cors())
app.use(postgraphile(database, schemas, options))

export default app
