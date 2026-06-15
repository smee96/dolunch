import { Hono } from 'hono'
import { AppContext } from '../index'
import { signJwt, nanoid } from '../utils/jwt'

export const authRoutes = new Hono<AppContext>()

// 카카오 OAuth 로그인 (프론트에서 access_token 받아서 전달)
authRoutes.post('/kakao', async (c) => {
  const { access_token } = await c.req.json<{ access_token: string }>()
  if (!access_token) return c.json({ error: 'access_token required' }, 400)

  // 카카오 유저 정보 조회
  const kakaoRes = await fetch('https://kapi.kakao.com/v2/user/me', {
    headers: { Authorization: `Bearer ${access_token}` },
  })
  if (!kakaoRes.ok) return c.json({ error: 'Invalid kakao token' }, 401)

  const kakao = await kakaoRes.json<{ id: number; kakao_account?: { profile?: { nickname?: string } } }>()
  const kakaoId = String(kakao.id)
  const kakaoName = kakao.kakao_account?.profile?.nickname ?? '점심러'

  const db = c.env.DB

  // 기존 유저 조회
  let user = await db.prepare('SELECT * FROM users WHERE kakao_id = ?').bind(kakaoId).first<{ id: string; handle: string; name: string }>()

  if (!user) {
    // 신규 가입
    const id = nanoid()
    const handle = `@user_${nanoid(8)}`
    await db.prepare(
      'INSERT INTO users (id, kakao_id, name, handle) VALUES (?, ?, ?, ?)'
    ).bind(id, kakaoId, kakaoName, handle).run()
    user = { id, handle, name: kakaoName }
  }

  const token = await signJwt({ sub: user.id, handle: user.handle }, c.env.JWT_SECRET)
  return c.json({ token, user })
})

// 전화번호 인증 (OTP — MVP: 단순 검증)
authRoutes.post('/phone/request', async (c) => {
  const { phone } = await c.req.json<{ phone: string }>()
  if (!/^01[0-9]{8,9}$/.test(phone.replace(/-/g, ''))) {
    return c.json({ error: 'Invalid phone' }, 400)
  }
  const otp = Math.floor(100000 + Math.random() * 900000).toString()
  // KV에 5분 보관
  await c.env.SESSION.put(`otp:${phone}`, otp, { expirationTtl: 300 })
  // TODO: 실제 SMS 발송 (알리고, NHN SMS 등)
  return c.json({ ok: true, ...(c.env.ENVIRONMENT === 'development' ? { otp } : {}) })
})

authRoutes.post('/phone/verify', async (c) => {
  const { phone, otp, name } = await c.req.json<{ phone: string; otp: string; name?: string }>()
  const stored = await c.env.SESSION.get(`otp:${phone}`)
  if (!stored || stored !== otp) return c.json({ error: 'Invalid OTP' }, 400)

  await c.env.SESSION.delete(`otp:${phone}`)

  const db = c.env.DB
  let user = await db.prepare('SELECT * FROM users WHERE phone = ?').bind(phone).first<{ id: string; handle: string; name: string }>()

  if (!user) {
    const id = nanoid()
    const handle = `@user_${nanoid(8)}`
    const displayName = name ?? '점심러'
    await db.prepare(
      'INSERT INTO users (id, phone, name, handle) VALUES (?, ?, ?, ?)'
    ).bind(id, phone, displayName, handle).run()
    user = { id, handle, name: displayName }
  }

  const token = await signJwt({ sub: user.id, handle: user.handle }, c.env.JWT_SECRET)
  return c.json({ token, user })
})

// 내 프로필 조회
authRoutes.get('/me', async (c) => {
  const token = c.req.header('Authorization')?.replace('Bearer ', '')
  if (!token) return c.json({ error: 'Unauthorized' }, 401)
  // 간단히 payload decode
  try {
    const payload = JSON.parse(atob(token.split('.')[1]))
    const user = await c.env.DB.prepare('SELECT * FROM users WHERE id = ?').bind(payload.sub).first()
    if (!user) return c.json({ error: 'Not found' }, 404)
    return c.json({ user })
  } catch {
    return c.json({ error: 'Unauthorized' }, 401)
  }
})
