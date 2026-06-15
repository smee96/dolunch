import { MiddlewareHandler } from 'hono'
import { AppContext } from '../index'

export const authMiddleware: MiddlewareHandler<AppContext> = async (c, next) => {
  const token = c.req.header('Authorization')?.replace('Bearer ', '')
  if (!token) return c.json({ error: 'Unauthorized' }, 401)

  try {
    const [header, payload, sig] = token.split('.')
    if (!header || !payload || !sig) throw new Error('invalid token format')

    const data = JSON.parse(atob(payload))
    if (data.exp && data.exp < Math.floor(Date.now() / 1000)) {
      return c.json({ error: 'Token expired' }, 401)
    }

    // HMAC-SHA256 검증
    const encoder = new TextEncoder()
    const key = await crypto.subtle.importKey(
      'raw', encoder.encode(c.env.JWT_SECRET),
      { name: 'HMAC', hash: 'SHA-256' }, false, ['verify']
    )
    const valid = await crypto.subtle.verify(
      'HMAC', key,
      Uint8Array.from(atob(sig), (c) => c.charCodeAt(0)),
      encoder.encode(`${header}.${payload}`)
    )
    if (!valid) throw new Error('invalid signature')

    c.set('userId', data.sub)
    c.set('userHandle', data.handle)
    await next()
  } catch {
    return c.json({ error: 'Unauthorized' }, 401)
  }
}
