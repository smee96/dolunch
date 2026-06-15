import { Hono } from 'hono'
import { AppContext } from '../index'
import { nanoid } from '../utils/jwt'

export const adminRoutes = new Hono<AppContext>()

// ─── 대시보드 통계 ────────────────────────────────────────────────
adminRoutes.get('/stats', async (c) => {
  const db = c.env.DB
  const today = new Date().toISOString().slice(0, 10)

  const [
    totalUsers, newUsersToday,
    totalRooms, openRooms, doneRooms,
    totalApplications, pendingApplications,
    pendingSettlements, receiptPending,
    revenueRow, todayRevenueRow,
    noShowCount, attendedCount,
    totalDepositsRow
  ] = await Promise.all([
    db.prepare('SELECT COUNT(*) as n FROM users').first<{ n: number }>(),
    db.prepare("SELECT COUNT(*) as n FROM users WHERE created_at >= ?").bind(today).first<{ n: number }>(),
    db.prepare('SELECT COUNT(*) as n FROM rooms').first<{ n: number }>(),
    db.prepare("SELECT COUNT(*) as n FROM rooms WHERE status = 'open'").first<{ n: number }>(),
    db.prepare("SELECT COUNT(*) as n FROM rooms WHERE status = 'done'").first<{ n: number }>(),
    db.prepare('SELECT COUNT(*) as n FROM applications').first<{ n: number }>(),
    db.prepare("SELECT COUNT(*) as n FROM applications WHERE status = 'pending'").first<{ n: number }>(),
    db.prepare("SELECT COUNT(*) as n FROM settlements WHERE status = 'pending'").first<{ n: number }>(),
    db.prepare("SELECT COUNT(*) as n FROM settlements WHERE status = 'receipt_uploaded'").first<{ n: number }>(),
    db.prepare("SELECT COALESCE(SUM(platform_fee * joined_count),0) as total FROM rooms WHERE status = 'done'").first<{ total: number }>(),
    db.prepare(`SELECT COALESCE(SUM(r.platform_fee * r.joined_count),0) as total FROM rooms r WHERE r.status='done' AND date(r.meet_at) = ?`).bind(today).first<{ total: number }>(),
    db.prepare("SELECT COUNT(*) as n FROM applications WHERE attended = 0").first<{ n: number }>(),
    db.prepare("SELECT COUNT(*) as n FROM applications WHERE attended = 1").first<{ n: number }>(),
    db.prepare("SELECT COALESCE(SUM(deposit_amount),0) as total FROM applications WHERE deposit_payment_key IS NOT NULL AND status != 'rejected'").first<{ total: number }>(),
  ])

  return c.json({
    users: { total: totalUsers?.n ?? 0, newToday: newUsersToday?.n ?? 0 },
    rooms: { total: totalRooms?.n ?? 0, open: openRooms?.n ?? 0, done: doneRooms?.n ?? 0 },
    applications: { total: totalApplications?.n ?? 0, pending: pendingApplications?.n ?? 0 },
    settlements: { pending: pendingSettlements?.n ?? 0, receiptReady: receiptPending?.n ?? 0 },
    revenue: { total: revenueRow?.total ?? 0, today: todayRevenueRow?.total ?? 0 },
    attendance: {
      noShow: noShowCount?.n ?? 0,
      attended: attendedCount?.n ?? 0,
      noShowRate: attendedCount?.n
        ? Math.round((noShowCount?.n ?? 0) / ((noShowCount?.n ?? 0) + (attendedCount?.n ?? 0)) * 100)
        : 0,
    },
    deposits: { held: totalDepositsRow?.total ?? 0 },
  })
})

// 일별 매출 (최근 30일)
adminRoutes.get('/stats/revenue-daily', async (c) => {
  const rows = await c.env.DB.prepare(`
    SELECT date(meet_at) as day,
           SUM(platform_fee * joined_count) as revenue,
           COUNT(*) as rooms
    FROM rooms WHERE status = 'done' AND meet_at >= datetime('now','-30 days')
    GROUP BY day ORDER BY day ASC
  `).all<{ day: string; revenue: number; rooms: number }>()
  return c.json({ data: rows.results })
})

// ─── 유저 관리 ────────────────────────────────────────────────────
adminRoutes.get('/users', async (c) => {
  const { q = '', limit = '50', offset = '0', sort = 'created_at' } = c.req.query()
  const safeSort = ['created_at', 'hosting_count', 'rating', 'follower_count'].includes(sort)
    ? sort : 'created_at'

  const rows = await c.env.DB.prepare(`
    SELECT u.*,
      (SELECT COUNT(*) FROM rooms WHERE host_id = u.id) as room_count,
      (SELECT COUNT(*) FROM applications WHERE guest_id = u.id) as apply_count,
      (SELECT SUM(main_amount) FROM applications WHERE guest_id = u.id AND status='accepted') as total_spent
    FROM users u
    WHERE u.name LIKE ? OR u.handle LIKE ? OR u.phone LIKE ?
    ORDER BY ${safeSort} DESC
    LIMIT ? OFFSET ?
  `).bind(`%${q}%`, `%${q}%`, `%${q}%`, Number(limit), Number(offset)).all()

  const total = await c.env.DB.prepare(
    'SELECT COUNT(*) as n FROM users WHERE name LIKE ? OR handle LIKE ?'
  ).bind(`%${q}%`, `%${q}%`).first<{ n: number }>()

  return c.json({ users: rows.results, total: total?.n ?? 0 })
})

adminRoutes.get('/users/:id', async (c) => {
  const user = await c.env.DB.prepare('SELECT * FROM users WHERE id = ?').bind(c.req.param('id')).first()
  if (!user) return c.json({ error: 'Not found' }, 404)

  const rooms = await c.env.DB.prepare('SELECT * FROM rooms WHERE host_id = ? ORDER BY created_at DESC LIMIT 10').bind(c.req.param('id')).all()
  const applications = await c.env.DB.prepare(`
    SELECT a.*, r.title as room_title FROM applications a
    JOIN rooms r ON a.room_id = r.id
    WHERE a.guest_id = ? ORDER BY a.created_at DESC LIMIT 10
  `).bind(c.req.param('id')).all()

  return c.json({ user, rooms: rooms.results, applications: applications.results })
})

adminRoutes.patch('/users/:id', async (c) => {
  const { is_business, biz_reg_no, memo } = await c.req.json<{
    is_business?: number; biz_reg_no?: string; memo?: string
  }>()
  const sets: string[] = []
  const vals: unknown[] = []
  if (is_business !== undefined) { sets.push('is_business = ?'); vals.push(is_business) }
  if (biz_reg_no !== undefined) { sets.push('biz_reg_no = ?'); vals.push(biz_reg_no) }
  if (!sets.length) return c.json({ error: 'Nothing to update' }, 400)
  sets.push("updated_at = datetime('now')")
  vals.push(c.req.param('id'))
  await c.env.DB.prepare(`UPDATE users SET ${sets.join(', ')} WHERE id = ?`).bind(...vals).run()
  return c.json({ ok: true })
})

// ─── 방 관리 ─────────────────────────────────────────────────────
adminRoutes.get('/rooms', async (c) => {
  const { status = '', q = '', limit = '50', offset = '0' } = c.req.query()
  const where = ['1=1']
  const vals: unknown[] = []
  if (status) { where.push('r.status = ?'); vals.push(status) }
  if (q) { where.push('(r.title LIKE ? OR r.place_name LIKE ?)'); vals.push(`%${q}%`, `%${q}%`) }
  vals.push(Number(limit), Number(offset))

  const rows = await c.env.DB.prepare(`
    SELECT r.*, u.name as host_name, u.handle as host_handle
    FROM rooms r JOIN users u ON r.host_id = u.id
    WHERE ${where.join(' AND ')}
    ORDER BY r.created_at DESC LIMIT ? OFFSET ?
  `).bind(...vals).all()

  return c.json({ rooms: rows.results })
})

adminRoutes.patch('/rooms/:id/cancel', async (c) => {
  const { reason } = await c.req.json<{ reason: string }>()
  const room = await c.env.DB.prepare('SELECT * FROM rooms WHERE id = ?').bind(c.req.param('id')).first<{ id: string; status: string }>()
  if (!room) return c.json({ error: 'Not found' }, 404)
  if (room.status === 'done') return c.json({ error: 'Already done' }, 400)

  // 모든 지원자 보증금 환불 + 수락된 게스트 본결제 환불
  const apps = await c.env.DB.prepare(
    "SELECT * FROM applications WHERE room_id = ? AND status IN ('pending','accepted')"
  ).bind(c.req.param('id')).all<{ id: string; deposit_payment_key: string | null; main_payment_key: string | null }>()

  const refundOps = (apps.results ?? []).flatMap((app) => {
    const ops = []
    if (app.deposit_payment_key) {
      ops.push(fetch(`${c.env.TOSS_API_URL}/v1/payments/${app.deposit_payment_key}/cancel`, {
        method: 'POST',
        headers: { Authorization: `Basic ${btoa(c.env.TOSS_SECRET_KEY + ':')}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ cancelReason: `어드민 모임 취소: ${reason}` }),
      }))
    }
    if (app.main_payment_key) {
      ops.push(fetch(`${c.env.TOSS_API_URL}/v1/payments/${app.main_payment_key}/cancel`, {
        method: 'POST',
        headers: { Authorization: `Basic ${btoa(c.env.TOSS_SECRET_KEY + ':')}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ cancelReason: `어드민 모임 취소: ${reason}` }),
      }))
    }
    return ops
  })

  await Promise.allSettled(refundOps)

  await c.env.DB.batch([
    c.env.DB.prepare("UPDATE rooms SET status = 'cancelled', updated_at = datetime('now') WHERE id = ?").bind(c.req.param('id')),
    c.env.DB.prepare("UPDATE applications SET status = 'cancelled', updated_at = datetime('now') WHERE room_id = ?").bind(c.req.param('id')),
  ])

  return c.json({ ok: true, refunded: refundOps.length })
})

// ─── 정산 관리 ────────────────────────────────────────────────────
adminRoutes.get('/settlements', async (c) => {
  const { status = '' } = c.req.query()
  const rows = await c.env.DB.prepare(`
    SELECT s.*, r.title as room_title, r.meet_at, r.joined_count,
           u.name as host_name, u.handle as host_handle, u.is_business, u.biz_reg_no
    FROM settlements s
    JOIN rooms r ON s.room_id = r.id
    JOIN users u ON s.host_id = u.id
    ${status ? 'WHERE s.status = ?' : ''}
    ORDER BY s.created_at DESC LIMIT 100
  `).bind(...(status ? [status] : [])).all()
  return c.json({ settlements: rows.results })
})

// 영수증 검토 → 정산 승인
adminRoutes.patch('/settlements/:id/approve', async (c) => {
  const s = await c.env.DB.prepare('SELECT * FROM settlements WHERE id = ?')
    .bind(c.req.param('id')).first<{ id: string; status: string; final_payout: number; host_id: string }>()
  if (!s) return c.json({ error: 'Not found' }, 404)
  if (s.status !== 'receipt_uploaded') return c.json({ error: 'Receipt not uploaded yet' }, 400)

  await c.env.DB.prepare(`
    UPDATE settlements SET status = 'processing', receipt_verified = 1, updated_at = datetime('now') WHERE id = ?
  `).bind(s.id).run()

  // TODO: 실제 계좌 송금 API 연동 (토스 정산 API or 은행 API)
  return c.json({ ok: true, finalPayout: s.final_payout })
})

adminRoutes.patch('/settlements/:id/reject', async (c) => {
  const { reason } = await c.req.json<{ reason: string }>()
  await c.env.DB.prepare(`
    UPDATE settlements SET status = 'pending', receipt_url = NULL, receipt_amount = NULL,
    receipt_verified = 0, updated_at = datetime('now') WHERE id = ?
  `).bind(c.req.param('id')).run()
  return c.json({ ok: true, reason })
})

adminRoutes.patch('/settlements/:id/paid', async (c) => {
  await c.env.DB.prepare(`
    UPDATE settlements SET status = 'paid', paid_at = datetime('now'), updated_at = datetime('now') WHERE id = ?
  `).bind(c.req.param('id')).run()
  return c.json({ ok: true })
})

// ─── 결제 로그 ────────────────────────────────────────────────────
adminRoutes.get('/payments', async (c) => {
  const { type = '', limit = '100', offset = '0' } = c.req.query()
  const rows = await c.env.DB.prepare(`
    SELECT * FROM payment_logs
    ${type ? 'WHERE type = ?' : ''}
    ORDER BY created_at DESC LIMIT ? OFFSET ?
  `).bind(...(type ? [type, Number(limit), Number(offset)] : [Number(limit), Number(offset)])).all()
  return c.json({ payments: rows.results })
})

// 수동 환불
adminRoutes.post('/payments/refund', async (c) => {
  const { paymentKey, amount, reason } = await c.req.json<{ paymentKey: string; amount: number; reason: string }>()
  const tossRes = await fetch(`${c.env.TOSS_API_URL}/v1/payments/${paymentKey}/cancel`, {
    method: 'POST',
    headers: {
      Authorization: `Basic ${btoa(c.env.TOSS_SECRET_KEY + ':')}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ cancelReason: reason, cancelAmount: amount }),
  })
  const data = await tossRes.json()
  if (!tossRes.ok) return c.json({ error: 'Refund failed', detail: data }, 400)

  await c.env.DB.prepare(`
    INSERT INTO payment_logs (id, payment_key, order_id, type, amount, status, raw_json)
    VALUES (?, ?, ?, 'refund', ?, 'DONE', ?)
  `).bind(nanoid(), paymentKey, `refund_${nanoid(8)}`, amount, JSON.stringify(data)).run()

  return c.json({ ok: true })
})

// ─── 노쇼 처리 ────────────────────────────────────────────────────
adminRoutes.post('/applications/:id/noshow', async (c) => {
  const app = await c.env.DB.prepare(`
    SELECT a.*, r.deposit_amount FROM applications a
    JOIN rooms r ON a.room_id = r.id WHERE a.id = ?
  `).bind(c.req.param('id')).first<{
    id: string; deposit_payment_key: string | null; deposit_amount: number; noshow_deducted: number
  }>()
  if (!app) return c.json({ error: 'Not found' }, 404)
  if (app.noshow_deducted) return c.json({ error: 'Already deducted' }, 400)
  if (!app.deposit_payment_key) return c.json({ error: 'No deposit to deduct' }, 400)

  // 보증금 차감 (환불 안 함 = 취소 API 안 호출)
  await c.env.DB.prepare(`
    UPDATE applications SET attended = 0, noshow_deducted = 1, updated_at = datetime('now') WHERE id = ?
  `).bind(app.id).run()

  return c.json({ ok: true, deducted: app.deposit_amount })
})

// 출석 확인
adminRoutes.post('/applications/:id/attend', async (c) => {
  await c.env.DB.prepare(`
    UPDATE applications SET attended = 1, updated_at = datetime('now') WHERE id = ?
  `).bind(c.req.param('id')).run()
  return c.json({ ok: true })
})
