import { Hono } from 'hono'
import { cors } from 'hono/cors'
import { logger } from 'hono/logger'
import * as Sentry from '@sentry/cloudflare'
import { authRoutes } from './routes/auth'
import { reelRoutes } from './routes/reels'
import { roomRoutes } from './routes/rooms'
import { applicationRoutes } from './routes/applications'
import { settlementRoutes } from './routes/settlements'
import { mediaRoutes } from './routes/media'
import { userRoutes } from './routes/users'
import { commentRoutes } from './routes/comments'
import { searchRoutes } from './routes/search'
import { adminRoutes } from './routes/admin'
import { authMiddleware } from './middleware/auth'
import { adminMiddleware } from './middleware/admin'
import { signJwt } from './utils/jwt'

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
  SENTRY_DSN?: string
}

export type AppContext = {
  Bindings: Env & { ADMIN_SECRET: string; ADMIN_USERNAME?: string; ADMIN_PASSWORD?: string; TOSS_API_URL: string; TOSS_SECRET_KEY: string }
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

// 어드민 로그인 (공개)
app.post('/admin/login', async (c) => {
  const { username, password } = await c.req.json<{ username: string; password: string }>()
  const validUser = c.env.ADMIN_USERNAME ?? 'admin'
  const validPass = c.env.ADMIN_PASSWORD ?? c.env.ADMIN_SECRET
  if (username !== validUser || password !== validPass) {
    return c.json({ error: '아이디 또는 비밀번호가 올바르지 않습니다.' }, 401)
  }
  const token = await signJwt({ sub: 'admin', role: 'admin' }, c.env.JWT_SECRET, 60 * 60 * 24 * 7)
  return c.json({ token })
})

// 인증 필요
const api = new Hono<AppContext>()
api.use('*', authMiddleware)
api.route('/reels', reelRoutes)
api.route('/rooms', roomRoutes)
api.route('/applications', applicationRoutes)
api.route('/settlements', settlementRoutes)
api.route('/media', mediaRoutes)
api.route('/users', userRoutes)
api.route('/search', searchRoutes)
api.route('/', commentRoutes)

app.route('/api', api)

// 어드민 (별도 미들웨어)
const admin = new Hono<AppContext>()
admin.use('*', adminMiddleware)
admin.route('/', adminRoutes)
app.route('/admin', admin)

// Sentry 에러 캡처 래퍼
export default {
  fetch(request: Request, env: AppContext['Bindings'], ctx: ExecutionContext) {
    if (!env.SENTRY_DSN) return app.fetch(request, env, ctx)
    return Sentry.withSentry(
      () => ({
        dsn: env.SENTRY_DSN!,
        environment: env.ENVIRONMENT,
        tracesSampleRate: env.ENVIRONMENT === 'production' ? 0.2 : 1.0,
      }),
      app,
    ).fetch(request, env, ctx)
  },
}
