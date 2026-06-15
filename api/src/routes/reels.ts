import { Hono } from 'hono'
import { AppContext } from '../index'
import { nanoid } from '../utils/jwt'

export const reelRoutes = new Hono<AppContext>()

// 숏츠 피드 (팔로잉 + 둘러보기)
reelRoutes.get('/feed', async (c) => {
  const userId = c.get('userId')
  const { type = 'explore', limit = '20', offset = '0' } = c.req.query()

  let query: string
  if (type === 'following') {
    query = `
      SELECT re.*, u.name as host_name, u.handle as host_handle,
             u.avatar_url as host_avatar, u.follower_count as host_followers,
             ro.id as room_id, ro.title as room_title, ro.meet_at as room_meet_at,
             ro.capacity - ro.joined_count as room_spots, ro.deposit_amount, ro.status as room_status
      FROM reels re
      JOIN users u ON re.host_id = u.id
      LEFT JOIN rooms ro ON re.id = ro.reel_id AND ro.status = 'open'
      WHERE re.is_active = 1 AND re.host_id IN (
        SELECT followee_id FROM follows WHERE follower_id = ?
      )
      ORDER BY re.created_at DESC LIMIT ? OFFSET ?
    `
  } else {
    query = `
      SELECT re.*, u.name as host_name, u.handle as host_handle,
             u.avatar_url as host_avatar, u.follower_count as host_followers,
             ro.id as room_id, ro.title as room_title, ro.meet_at as room_meet_at,
             ro.capacity - ro.joined_count as room_spots, ro.deposit_amount, ro.status as room_status
      FROM reels re
      JOIN users u ON re.host_id = u.id
      LEFT JOIN rooms ro ON re.id = ro.reel_id AND ro.status = 'open'
      WHERE re.is_active = 1
      ORDER BY re.created_at DESC LIMIT ? OFFSET ?
    `
  }

  const params = type === 'following'
    ? [userId, Number(limit), Number(offset)]
    : [Number(limit), Number(offset)]

  const rows = await c.env.DB.prepare(query).bind(...params).all()
  return c.json({ reels: rows.results })
})

// 숏츠 등록 (R2 업로드 후 URL 전달)
reelRoutes.post('/', async (c) => {
  const userId = c.get('userId')
  const { video_url, thumb_url, caption, room_id } = await c.req.json<{
    video_url: string; thumb_url?: string; caption?: string; room_id?: string
  }>()

  if (!video_url) return c.json({ error: 'video_url required' }, 400)

  const id = nanoid()
  await c.env.DB.prepare(`
    INSERT INTO reels (id, host_id, video_url, thumb_url, caption)
    VALUES (?, ?, ?, ?, ?)
  `).bind(id, userId, video_url, thumb_url ?? null, caption ?? '').run()

  // 방과 연결
  if (room_id) {
    await c.env.DB.prepare('UPDATE rooms SET reel_id = ? WHERE id = ? AND host_id = ?')
      .bind(id, room_id, userId).run()
  }

  return c.json({ id }, 201)
})

// 좋아요 토글
reelRoutes.post('/:id/like', async (c) => {
  const userId = c.get('userId')
  const reelId = c.req.param('id')

  const existing = await c.env.DB.prepare('SELECT 1 FROM reel_likes WHERE reel_id = ? AND user_id = ?')
    .bind(reelId, userId).first()

  if (existing) {
    await c.env.DB.batch([
      c.env.DB.prepare('DELETE FROM reel_likes WHERE reel_id = ? AND user_id = ?').bind(reelId, userId),
      c.env.DB.prepare('UPDATE reels SET like_count = like_count - 1 WHERE id = ?').bind(reelId),
    ])
    return c.json({ liked: false })
  } else {
    await c.env.DB.batch([
      c.env.DB.prepare('INSERT INTO reel_likes (reel_id, user_id) VALUES (?, ?)').bind(reelId, userId),
      c.env.DB.prepare('UPDATE reels SET like_count = like_count + 1 WHERE id = ?').bind(reelId),
    ])
    return c.json({ liked: true })
  }
})
