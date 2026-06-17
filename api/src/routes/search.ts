import { Hono } from 'hono'
import { AppContext } from '../index'

export const searchRoutes = new Hono<AppContext>()

// GET /api/search?q=...&type=all|rooms|hosts
searchRoutes.get('/', async (c) => {
  const q = (c.req.query('q') ?? '').trim()
  const type = c.req.query('type') ?? 'all'
  const limit = Math.min(Number(c.req.query('limit') ?? 20), 50)

  if (!q) return c.json({ rooms: [], hosts: [] })

  const pattern = `%${q}%`

  const [rooms, hosts] = await Promise.all([
    (type === 'all' || type === 'rooms')
      ? c.env.DB.prepare(`
          SELECT r.id, r.title, r.place_name, r.meet_at, r.price_per_person,
                 r.capacity, r.joined_count, r.status,
                 u.name as host_name, u.avatar_url as host_avatar
          FROM rooms r JOIN users u ON r.host_id = u.id
          WHERE (r.title LIKE ? OR r.place_name LIKE ? OR r.menu LIKE ?)
            AND r.status = 'open'
          ORDER BY r.meet_at ASC
          LIMIT ?
        `).bind(pattern, pattern, pattern, limit).all()
      : Promise.resolve({ results: [] }),

    (type === 'all' || type === 'hosts')
      ? c.env.DB.prepare(`
          SELECT id, name, handle, bio, avatar_url, follower_count, hosting_count, rating
          FROM users
          WHERE name LIKE ? OR handle LIKE ? OR bio LIKE ?
          ORDER BY follower_count DESC
          LIMIT ?
        `).bind(pattern, pattern, pattern, limit).all()
      : Promise.resolve({ results: [] }),
  ])

  return c.json({ rooms: rooms.results, hosts: hosts.results })
})
