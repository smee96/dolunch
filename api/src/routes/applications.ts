import { Hono } from 'hono'
import { AppContext } from '../index'
import { nanoid } from '../utils/jwt'

export const applicationRoutes = new Hono<AppContext>()

// 방 지원 (보증금 예치)
applicationRoutes.post('/rooms/:roomId/apply', async (c) => {
  const userId = c.get('userId')
  const roomId = c.req.param('roomId')

  const room = await c.env.DB.prepare('SELECT * FROM rooms WHERE id = ? AND status = \'open\'')
    .bind(roomId).first<{ id: string; host_id: string; deposit_amount: number; price_per_person: number; capacity: number; joined_count: number }>()
  if (!room) return c.json({ error: 'Room not found or not open' }, 404)
  if (room.host_id === userId) return c.json({ error: 'Host cannot apply to own room' }, 400)
  if (room.joined_count >= room.capacity) return c.json({ error: 'Room is full' }, 400)

  const existing = await c.env.DB.prepare('SELECT id FROM applications WHERE room_id = ? AND guest_id = ?')
    .bind(roomId, userId).first()
  if (existing) return c.json({ error: 'Already applied' }, 400)

  const id = nanoid()
  await c.env.DB.prepare(`
    INSERT INTO applications (id, room_id, guest_id, deposit_amount, main_amount)
    VALUES (?, ?, ?, ?, ?)
  `).bind(id, roomId, userId, room.deposit_amount, room.price_per_person).run()

  // Toss 보증금 결제 URL 생성 (실제 연동 시 교체)
  const orderName = `[점심어때] 보증금 ${room.deposit_amount.toLocaleString()}원`
  return c.json({
    applicationId: id,
    depositAmount: room.deposit_amount,
    orderId: `dep_${id}`,
    orderName,
    // 클라이언트에서 Toss SDK로 결제 진행
  }, 201)
})

// 목 결제 확인 (실제 PG 연동 전 개발/테스트용)
applicationRoutes.post('/applications/:id/deposit/mock', async (c) => {
  const appId = c.req.param('id')
  const app = await c.env.DB.prepare('SELECT * FROM applications WHERE id = ?')
    .bind(appId).first<{ id: string; deposit_amount: number; room_id: string; deposit_payment_key: string | null }>()
  if (!app) return c.json({ error: 'Not found' }, 404)
  if (app.deposit_payment_key) return c.json({ error: 'Already paid' }, 400)

  const mockKey = `mock_${nanoid()}`
  await c.env.DB.batch([
    c.env.DB.prepare(`
      UPDATE applications SET deposit_payment_key = ?, deposit_paid_at = datetime('now'), updated_at = datetime('now')
      WHERE id = ?
    `).bind(mockKey, appId),
    c.env.DB.prepare(`
      INSERT INTO payment_logs (id, payment_key, order_id, type, amount, status, raw_json)
      VALUES (?, ?, ?, 'deposit', ?, 'DONE', ?)
    `).bind(nanoid(), mockKey, `mock_order_${appId}`, app.deposit_amount, JSON.stringify({ mock: true })),
  ])
  return c.json({ ok: true, paymentKey: mockKey })
})

// Toss 보증금 결제 성공 콜백
applicationRoutes.post('/applications/:id/deposit/confirm', async (c) => {
  const { paymentKey, orderId, amount } = await c.req.json<{ paymentKey: string; orderId: string; amount: number }>()
  const appId = c.req.param('id')

  const app = await c.env.DB.prepare('SELECT * FROM applications WHERE id = ?')
    .bind(appId).first<{ id: string; deposit_amount: number; room_id: string }>()
  if (!app) return c.json({ error: 'Not found' }, 404)
  if (amount !== app.deposit_amount) return c.json({ error: 'Amount mismatch' }, 400)

  // Toss 결제 승인 API 호출
  const tossRes = await fetch(`${c.env.TOSS_API_URL}/v1/payments/confirm`, {
    method: 'POST',
    headers: {
      'Authorization': `Basic ${btoa(c.env.TOSS_SECRET_KEY + ':')}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ paymentKey, orderId, amount }),
  })

  if (!tossRes.ok) {
    const err = await tossRes.json()
    return c.json({ error: 'Payment failed', detail: err }, 400)
  }

  const tossData = await tossRes.json<{ paymentKey: string; status: string }>()

  await c.env.DB.batch([
    c.env.DB.prepare(`
      UPDATE applications SET deposit_payment_key = ?, deposit_paid_at = datetime('now'), updated_at = datetime('now')
      WHERE id = ?
    `).bind(paymentKey, appId),
    c.env.DB.prepare(`
      INSERT INTO payment_logs (id, payment_key, order_id, type, amount, status, raw_json)
      VALUES (?, ?, ?, 'deposit', ?, ?, ?)
    `).bind(nanoid(), paymentKey, orderId, amount, tossData.status, JSON.stringify(tossData)),
  ])

  return c.json({ ok: true })
})

// 내가 지원한 목록 (게스트 뷰)
applicationRoutes.get('/mine', async (c) => {
  const userId = c.get('userId')
  const rows = await c.env.DB.prepare(`
    SELECT a.id, a.room_id, a.status, a.deposit_amount, a.deposit_payment_key,
           r.title AS room_title, r.place_name, r.meet_at
    FROM applications a JOIN rooms r ON a.room_id = r.id
    WHERE a.guest_id = ?
    ORDER BY a.created_at DESC
  `).bind(userId).all()
  return c.json({ applications: rows.results })
})

// 호스트가 지원자 목록 조회
applicationRoutes.get('/rooms/:roomId/applicants', async (c) => {
  const userId = c.get('userId')
  const roomId = c.req.param('roomId')

  const room = await c.env.DB.prepare('SELECT host_id FROM rooms WHERE id = ?').bind(roomId).first<{ host_id: string }>()
  if (!room || room.host_id !== userId) return c.json({ error: 'Forbidden' }, 403)

  const rows = await c.env.DB.prepare(`
    SELECT a.*, u.name, u.handle, u.avatar_url, u.rating, u.hosting_count
    FROM applications a JOIN users u ON a.guest_id = u.id
    WHERE a.room_id = ?
    ORDER BY a.created_at ASC
  `).bind(roomId).all()
  return c.json({ applicants: rows.results })
})

// 호스트 수락/거절
applicationRoutes.patch('/applications/:id/decide', async (c) => {
  const userId = c.get('userId')
  const body = await c.req.json<{ decision?: 'accepted' | 'rejected'; action?: 'accept' | 'reject' }>()
  const decision = body.decision ?? (body.action === 'accept' ? 'accepted' : body.action === 'reject' ? 'rejected' : undefined)
  if (!decision || !['accepted', 'rejected'].includes(decision)) return c.json({ error: 'Invalid decision' }, 400)

  const app = await c.env.DB.prepare(`
    SELECT a.*, r.host_id, r.capacity, r.joined_count, r.deposit_amount
    FROM applications a JOIN rooms r ON a.room_id = r.id
    WHERE a.id = ?
  `).bind(c.req.param('id')).first<{
    id: string; room_id: string; guest_id: string; deposit_payment_key: string | null
    host_id: string; capacity: number; joined_count: number; status: string
  }>()

  if (!app) return c.json({ error: 'Not found' }, 404)
  if (app.host_id !== userId) return c.json({ error: 'Forbidden' }, 403)
  if (app.status !== 'pending') return c.json({ error: 'Already decided' }, 400)
  if (!app.deposit_payment_key) return c.json({ error: 'Deposit not paid' }, 400)

  if (decision === 'accepted' && app.joined_count >= app.capacity) {
    return c.json({ error: 'Room is full' }, 400)
  }

  const ops = [
    c.env.DB.prepare(`UPDATE applications SET status = ?, updated_at = datetime('now') WHERE id = ?`)
      .bind(decision, app.id),
  ]
  if (decision === 'accepted') {
    ops.push(c.env.DB.prepare(`UPDATE rooms SET joined_count = joined_count + 1, updated_at = datetime('now') WHERE id = ?`)
      .bind(app.room_id))
  }
  await c.env.DB.batch(ops)

  // 거절 시 보증금 자동 환불 (Toss)
  if (decision === 'rejected' && app.deposit_payment_key) {
    await refundDeposit(c.env, app.deposit_payment_key, app.id)
  }

  return c.json({ ok: true, status: decision })
})

// 출석 체크 (호스트가 모임 후 출석/노쇼 기록)
applicationRoutes.patch('/applications/:id/attendance', async (c) => {
  const userId = c.get('userId')
  const appId = c.req.param('id')
  const { attended } = await c.req.json<{ attended: 0 | 1 }>()
  if (attended !== 0 && attended !== 1) return c.json({ error: 'Invalid attended value' }, 400)

  const app = await c.env.DB.prepare(`
    SELECT a.*, r.host_id, r.status as room_status, r.deposit_amount
    FROM applications a JOIN rooms r ON a.room_id = r.id
    WHERE a.id = ?
  `).bind(appId).first<{
    id: string; room_id: string; guest_id: string; status: string;
    host_id: string; room_status: string; deposit_amount: number;
    deposit_payment_key: string | null; attended: number | null;
  }>()

  if (!app) return c.json({ error: 'Not found' }, 404)
  if (app.host_id !== userId) return c.json({ error: 'Forbidden' }, 403)
  if (app.status !== 'accepted') return c.json({ error: 'Applicant not accepted' }, 400)
  if (app.room_status !== 'done') return c.json({ error: 'Room not finished yet' }, 400)
  if (app.attended !== null) return c.json({ error: 'Attendance already recorded' }, 400)

  await c.env.DB.prepare(`UPDATE applications SET attended = ?, updated_at = datetime('now') WHERE id = ?`)
    .bind(attended, appId).run()

  // 노쇼: 보증금 환불 없음 (호스트에게 귀속)
  // 출석: 보증금 환불
  if (attended === 1 && app.deposit_payment_key) {
    await refundDeposit(c.env, app.deposit_payment_key, appId)
  }

  return c.json({ ok: true, attended })
})

async function refundDeposit(env: AppContext['Bindings'], paymentKey: string, appId: string) {
  await fetch(`${env.TOSS_API_URL}/v1/payments/${paymentKey}/cancel`, {
    method: 'POST',
    headers: {
      'Authorization': `Basic ${btoa(env.TOSS_SECRET_KEY + ':')}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ cancelReason: '지원자 미선정 — 보증금 전액 환불' }),
  })
}
