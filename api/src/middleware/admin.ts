import { MiddlewareHandler } from 'hono'
import { AppContext } from '../index'

export const adminMiddleware: MiddlewareHandler<AppContext> = async (c, next) => {
  const auth = c.req.header('Authorization') ?? ''
  const token = auth.startsWith('Bearer ') ? auth.slice(7) : ''
  if (!token) return c.json({ error: 'Unauthorized' }, 401)

  try {
    const [header, payload, sig] = token.split('.')
    if (!header || !payload || !sig) throw new Error('bad token')
    const data = JSON.parse(atob(payload))
    if (data.role !== 'admin') throw new Error('not admin')
    if (data.exp && data.exp < Math.floor(Date.now() / 1000)) return c.json({ error: 'Token expired' }, 401)

    const encoder = new TextEncoder()
    const key = await crypto.subtle.importKey(
      'raw', encoder.encode(c.env.JWT_SECRET),
      { name: 'HMAC', hash: 'SHA-256' }, false, ['verify'],
    )
    const valid = await crypto.subtle.verify(
      'HMAC', key,
      Uint8Array.from(atob(sig), (ch) => ch.charCodeAt(0)),
      encoder.encode(`${header}.${payload}`),
    )
    if (!valid) throw new Error('invalid sig')
    await next()
  } catch {
    return c.json({ error: 'Unauthorized' }, 401)
  }
}
