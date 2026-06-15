import { MiddlewareHandler } from 'hono'
import { AppContext } from '../index'

export const adminMiddleware: MiddlewareHandler<AppContext> = async (c, next) => {
  const token = c.req.header('X-Admin-Token')
  if (!token || token !== c.env.ADMIN_SECRET) {
    return c.json({ error: 'Forbidden' }, 403)
  }
  await next()
}
