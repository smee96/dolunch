import { Hono } from 'hono'
import { cors } from 'hono/cors'
import { logger } from 'hono/logger'
import { authRoutes } from './routes/auth'
import { reelRoutes } from './routes/reels'
import { roomRoutes } from './routes/rooms'
import { applicationRoutes } from './routes/applications'
import { settlementRoutes } from './routes/settlements'
import { mediaRoutes } from './routes/media'
import { authMiddleware } from './middleware/auth'

export type Env = {
  DB: D1Database
  MEDIA: R2Bucket
  SESSION: KVNamespace
  JWT_SECRET: string
  TOSS_SECRET_KEY: string
  TOSS_API_URL: string
  KAKAO_CLIENT_ID: string
  DEPOSIT_RATIO: string
  PLATFORM_FEE_RATIO: string
  WITHHOLDING_TAX_RATE: string
  ENVIRONMENT: string
}

export type AppContext = {
  Bindings: Env
  Variables: {
    userId: string
    userHandle: string
  }
}

const app = new Hono<AppContext>()

app.use('*', logger())
app.use('*', cors({ origin: '*', allowMethods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'] }))

app.get('/health', (c) => c.json({ ok: true, env: c.env.ENVIRONMENT }))

// 인증 불필요
app.route('/auth', authRoutes)

// 인증 필요
const api = new Hono<AppContext>()
api.use('*', authMiddleware)
api.route('/reels', reelRoutes)
api.route('/rooms', roomRoutes)
api.route('/applications', applicationRoutes)
api.route('/settlements', settlementRoutes)
api.route('/media', mediaRoutes)

app.route('/api', api)

export default app
