import { Hono } from 'hono'
import { AppContext } from '../index'
import { nanoid, calcPricing } from '../utils/jwt'

export const roomRoutes = new Hono<AppContext>()

// 방 목록 (피드용 — 공개)
roomRoutes.get('/', async (c) => {
  const { status = 'open', limit = '20', offset = '0', host_id } = c.req.query()

  let query: string
  let params: unknown[]

  if (host_id) {
    query = `
      SELECT r.*, u.name as host_name, u.handle as host_handle, u.avatar_url as host_avatar,
             u.rating as host_rating, u.follower_count as host_followers
      FROM rooms r JOIN users u ON r.host_id = u.id
      WHERE r.host_id = ?
      ORDER BY r.created_at DESC LIMIT ? OFFSET ?
    `
    params = [host_id, Number(limit), Number(offset)]
  } else {
    query = `
      SELECT r.*, u.name as host_name, u.handle as host_handle, u.avatar_url as host_avatar,
             u.rating as host_rating, u.follower_count as host_followers
      FROM rooms r JOIN users u ON r.host_id = u.id
      WHERE r.status = ?
      ORDER BY r.meet_at ASC LIMIT ? OFFSET ?
    `
    params = [status, Number(limit), Number(offset)]
  }

  const rows = await c.env.DB.prepare(query).bind(...params).all()
  return c.json({ rooms: rows.results })
})

// 내 방 목록
roomRoutes.get('/mine', async (c) => {
  const userId = c.get('userId')
  const rows = await c.env.DB.prepare(`
    SELECT * FROM rooms WHERE host_id = ? ORDER BY created_at DESC
  `).bind(userId).all()
  return c.json({ rooms: rows.results })
})

// 방 상세
roomRoutes.get('/:id', async (c) => {
  const room = await c.env.DB.prepare(`
    SELECT r.*, u.name as host_name, u.handle as host_handle,
           u.avatar_url as host_avatar, u.rating as host_rating,
           u.follower_count as host_followers, u.bio as host_bio
    FROM rooms r JOIN users u ON r.host_id = u.id
    WHERE r.id = ?
  `).bind(c.req.param('id')).first()
  if (!room) return c.json({ error: 'Not found' }, 404)
  return c.json({ room })
})

// 방 만들기
roomRoutes.post('/', async (c) => {
  const userId = c.get('userId')
  const body = await c.req.json<{
    title: string
    description?: string
    menu: string
    place_name: string
    place_address?: string
    meet_at: string
    capacity: number
    price_per_person: number
    reel_id?: string
  }>()

  const { title, menu, place_name, meet_at, capacity, price_per_person } = body
  if (!title || !menu || !place_name || !meet_at || !capacity || !price_per_person) {
    return c.json({ error: 'Missing required fields' }, 400)
  }
  if (price_per_person < 10000) return c.json({ error: 'Minimum price is 10,000 KRW' }, 400)
  if (capacity < 2 || capacity > 20) return c.json({ error: 'Capacity must be 2–20' }, 400)

  const depositRatio = parseFloat(c.env.DEPOSIT_RATIO)
  const platformFeeRatio = parseFloat(c.env.PLATFORM_FEE_RATIO)
  const { deposit, platformFee, hostRevenue } = calcPricing(price_per_person, depositRatio, platformFeeRatio)

  const id = nanoid()
  await c.env.DB.prepare(`
    INSERT INTO rooms
      (id, host_id, reel_id, title, description, menu, place_name, place_address,
       meet_at, capacity, price_per_person, deposit_amount, platform_fee, host_revenue)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `).bind(
    id, userId, body.reel_id ?? null, title, body.description ?? '',
    menu, place_name, body.place_address ?? null,
    meet_at, capacity, price_per_person, deposit, platformFee, hostRevenue
  ).run()

  return c.json({ id, deposit, platformFee, hostRevenue }, 201)
})

// 방 상태 업데이트 (호스트 전용)
roomRoutes.patch('/:id/status', async (c) => {
  const userId = c.get('userId')
  const { status } = await c.req.json<{ status: string }>()
  const allowed = ['open', 'full', 'done', 'cancelled']
  if (!allowed.includes(status)) return c.json({ error: 'Invalid status' }, 400)

  const room = await c.env.DB.prepare('SELECT * FROM rooms WHERE id = ? AND host_id = ?')
    .bind(c.req.param('id'), userId).first<{ id: string }>()
  if (!room) return c.json({ error: 'Forbidden' }, 403)

  await c.env.DB.prepare('UPDATE rooms SET status = ?, updated_at = datetime(\'now\') WHERE id = ?')
    .bind(status, c.req.param('id')).run()
  return c.json({ ok: true })
})
