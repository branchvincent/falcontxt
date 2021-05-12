import app from './app'
import { options, port } from './config'

const server = app.listen(port, () => {
  const address = server.address()
  if (typeof address !== 'string') {
    const href = `http://localhost:${address?.port}${
      options.graphiqlRoute || '/graphiql'
    }`
    console.log(`PostGraphiQL available at ${href} 🚀`)
  } else {
    console.log(`PostGraphile listening on ${address} 🚀`)
  }
})
