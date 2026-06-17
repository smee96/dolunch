import { Hono } from 'hono'
import { AppContext } from '../index'

export const userRoutes = new Hono<AppContext>()

// 내 프로필 (상세)
userRoutes.get('/me', async (c) => {
  const userId = c.get('userId')
  const user = await c.env.DB.prepare(`
    SELECT u.*,
      (SELECT COUNT(*) FROM follows WHERE followee_id = u.id) AS follower_count,
      (SELECT COUNT(*) FROM rooms WHERE host_id = u.id) AS hosting_count
    FROM users u WHERE u.id = ?
  `).bind(userId).first()
  if (!user) return c.json({ error: 'Not found' }, 404)
  return c.json({ user })
})

// 특정 유저 프로필 (is_following 포함)
userRoutes.get('/:id', async (c) => {
  const me = c.get('userId')
  const userId = c.req.param('id')
  const [user, following] = await Promise.all([
    c.env.DB.prepare(`
      SELECT u.id, u.name, u.handle, u.bio, u.avatar_url, u.rating, u.is_business,
        u.follower_count, u.hosting_count, u.rating_count
      FROM users u WHERE u.id = ?
    `).bind(userId).first(),
    c.env.DB.prepare('SELECT 1 FROM follows WHERE follower_id = ? AND followee_id = ?')
      .bind(me, userId).first(),
  ])
  if (!user) return c.json({ error: 'Not found' }, 404)
  return c.json({ user: { ...user, is_following: following != null } })
})

// 팔로우 토글
userRoutes.post('/:id/follow', async (c) => {
  const me = c.get('userId')
  const targetId = c.req.param('id')
  if (me === targetId) return c.json({ error: 'Cannot follow yourself' }, 400)

  const existing = await c.env.DB.prepare(
    'SELECT 1 FROM follows WHERE follower_id = ? AND followee_id = ?'
  ).bind(me, targetId).first()

  if (existing) {
    await c.env.DB.batch([
      c.env.DB.prepare('DELETE FROM follows WHERE follower_id = ? AND followee_id = ?').bind(me, targetId),
      c.env.DB.prepare('UPDATE users SET follower_count = MAX(0, follower_count - 1) WHERE id = ?').bind(targetId),
    ])
    return c.json({ following: false })
  } else {
    await c.env.DB.batch([
      c.env.DB.prepare('INSERT INTO follows (follower_id, followee_id) VALUES (?, ?)').bind(me, targetId),
      c.env.DB.prepare('UPDATE users SET follower_count = follower_count + 1 WHERE id = ?').bind(targetId),
    ])
    return c.json({ following: true })
  }
})

// 프로필 수정
userRoutes.patch('/me', async (c) => {
  const userId = c.get('userId')
  const { name, bio, handle, avatar_url } = await c.req.json<{
    name?: string; bio?: string; handle?: string; avatar_url?: string
  }>()

  const sets: string[] = []
  const vals: unknown[] = []
  if (name) { sets.push('name = ?'); vals.push(name) }
  if (bio !== undefined) { sets.push('bio = ?'); vals.push(bio) }
  if (handle) { sets.push('handle = ?'); vals.push(handle) }
  if (avatar_url) { sets.push('avatar_url = ?'); vals.push(avatar_url) }
  if (sets.length === 0) return c.json({ error: 'Nothing to update' }, 400)

  sets.push('updated_at = datetime(\'now\')')
  vals.push(userId)
  await c.env.DB.prepare(`UPDATE users SET ${sets.join(', ')} WHERE id = ?`).bind(...vals).run()

  const updated = await c.env.DB.prepare('SELECT * FROM users WHERE id = ?').bind(userId).first()
  return c.json({ ok: true, user: updated })
})
