import express from 'express'
import type { Request, Response } from 'express'
import { prisma } from '../lib/prisma.js'
const app = express()
const port = process.env.PORT || 3005

app.get('/', (_ : Request, res : Response) => {
  res.send('Hello World! this is the main route')
})

app.get('/users', async (_ : Request, res : Response) => {
  const users = await prisma.user.findMany()
  res.json(users)
})
app.listen(port, () => {
  console.log(`Example app listening on port ${port}`)
})
