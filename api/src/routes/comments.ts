import { Hono } from 'hono'
import { AppContext } from '../index'
import { nanoid } from '../utils/jwt'

export const commentRoutes = new Hono<AppContext>()

// GET /api/reels/:reelId/comments
commentRoutes.get('/reels/:reelId/comments', async (c) => {
  const reelId = c.req.param('reelId')
  const limit = Number(c.req.query('limit') ?? 30)
  const offset = Number(c.req.query('offset') ?? 0)

  const rows = await c.env.DB.prepare(`
    SELECT cm.id, cm.body, cm.created_at,
           u.id as user_id, u.name, u.handle, u.avatar_url
    FROM comments cm JOIN users u ON cm.user_id = u.id
    WHERE cm.reel_id = ?
    ORDER BY cm.created_at ASC
    LIMIT ? OFFSET ?
  `).bind(reelId, limit, offset).all()

  return c.json({ comments: rows.results })
})

// POST /api/reels/:reelId/comments
commentRoutes.post('/reels/:reelId/comments', async (c) => {
  const userId = c.get('userId')
  const reelId = c.req.param('reelId')
  const { body } = await c.req.json<{ body: string }>()

  if (!body?.trim()) return c.json({ error: 'Body required' }, 400)
  if (body.length > 500) return c.json({ error: 'Too long' }, 400)

  const reel = await c.env.DB.prepare('SELECT id FROM reels WHERE id = ?').bind(reelId).first()
  if (!reel) return c.json({ error: 'Reel not found' }, 404)

  const id = nanoid()
  await c.env.DB.batch([
    c.env.DB.prepare(`
      INSERT INTO comments (id, reel_id, user_id, body) VALUES (?, ?, ?, ?)
    `).bind(id, reelId, userId, body.trim()),
    c.env.DB.prepare(`
      UPDATE reels SET comment_count = comment_count + 1 WHERE id = ?
    `).bind(reelId),
  ])

  const comment = await c.env.DB.prepare(`
    SELECT cm.id, cm.body, cm.created_at,
           u.id as user_id, u.name, u.handle, u.avatar_url
    FROM comments cm JOIN users u ON cm.user_id = u.id
    WHERE cm.id = ?
  `).bind(id).first()

  return c.json({ comment }, 201)
})

// DELETE /api/comments/:id
commentRoutes.delete('/comments/:id', async (c) => {
  const userId = c.get('userId')
  const id = c.req.param('id')

  const cm = await c.env.DB.prepare('SELECT * FROM comments WHERE id = ?').bind(id).first<{ user_id: string; reel_id: string }>()
  if (!cm) return c.json({ error: 'Not found' }, 404)
  if (cm.user_id !== userId) return c.json({ error: 'Forbidden' }, 403)

  await c.env.DB.batch([
    c.env.DB.prepare('DELETE FROM comments WHERE id = ?').bind(id),
    c.env.DB.prepare('UPDATE reels SET comment_count = MAX(0, comment_count - 1) WHERE id = ?').bind(cm.reel_id),
  ])
  return c.json({ ok: true })
})
