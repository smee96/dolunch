import { Hono } from 'hono'
import { AppContext } from '../index'
import { nanoid } from '../utils/jwt'

export const settlementRoutes = new Hono<AppContext>()

const mySettlementsQuery = `
  SELECT s.id, s.room_id, r.title as room_title,
         s.gross_amount as total_amount,
         (s.gross_amount - COALESCE(s.withholding_tax, 0)) as host_amount,
         s.status, s.receipt_url,
         s.created_at as requested_at, s.updated_at as paid_at
  FROM settlements s JOIN rooms r ON s.room_id = r.id
  WHERE s.host_id = ?
  ORDER BY s.created_at DESC
`

// 정산 목록 (호스트)
settlementRoutes.get('/', async (c) => {
  const userId = c.get('userId')
  const rows = await c.env.DB.prepare(mySettlementsQuery).bind(userId).all()
  return c.json({ settlements: rows.results })
})

// alias for Flutter client
settlementRoutes.get('/mine', async (c) => {
  const userId = c.get('userId')
  const rows = await c.env.DB.prepare(mySettlementsQuery).bind(userId).all()
  return c.json({ settlements: rows.results })
})

// 정산 요청
settlementRoutes.post('/:id/request', async (c) => {
  const userId = c.get('userId')
  const settlementId = c.req.param('id')
  const s = await c.env.DB.prepare('SELECT * FROM settlements WHERE id = ? AND host_id = ?')
    .bind(settlementId, userId).first<{ id: string; status: string }>()
  if (!s) return c.json({ error: 'Not found or forbidden' }, 404)
  if (s.status !== 'pending') return c.json({ error: 'Already processed' }, 400)
  await c.env.DB.prepare(`UPDATE settlements SET status = 'requested', updated_at = datetime('now') WHERE id = ?`)
    .bind(settlementId).run()
  return c.json({ ok: true })
})

// 영수증 업로드 + 정산 확정
settlementRoutes.post('/:id/receipt', async (c) => {
  const userId = c.get('userId')
  const settlementId = c.req.param('id')
  const { receipt_url, receipt_amount } = await c.req.json<{ receipt_url: string; receipt_amount: number }>()

  const s = await c.env.DB.prepare('SELECT * FROM settlements WHERE id = ? AND host_id = ?')
    .bind(settlementId, userId).first<{
      id: string; gross_amount: number; is_business: number; status: string
    }>()
  if (!s) return c.json({ error: 'Not found or forbidden' }, 404)
  if (s.status !== 'pending') return c.json({ error: 'Already processed' }, 400)

  const netProfit = s.gross_amount - receipt_amount
  const withholdingTax = s.is_business ? 0 : Math.ceil(netProfit * 0.033)
  const finalPayout = netProfit - withholdingTax

  await c.env.DB.prepare(`
    UPDATE settlements SET
      receipt_url = ?, receipt_amount = ?,
      net_profit = ?, withholding_tax = ?, final_payout = ?,
      status = 'receipt_uploaded', updated_at = datetime('now')
    WHERE id = ?
  `).bind(receipt_url, receipt_amount, netProfit, withholdingTax, finalPayout, settlementId).run()

  return c.json({ netProfit, withholdingTax, finalPayout })
})

// 방 종료 후 정산 생성 (내부 호출)
export async function createSettlement(env: AppContext['Bindings'], roomId: string) {
  const room = await env.DB.prepare(`
    SELECT r.*, u.is_business FROM rooms r JOIN users u ON r.host_id = u.id WHERE r.id = ?
  `).bind(roomId).first<{
    id: string; host_id: string; host_revenue: number; is_business: number
  }>()
  if (!room) return

  const attendedCount = await env.DB.prepare(
    'SELECT COUNT(*) as cnt FROM applications WHERE room_id = ? AND attended = 1 AND status = \'accepted\''
  ).bind(roomId).first<{ cnt: number }>()

  const gross = room.host_revenue * (attendedCount?.cnt ?? 0)
  const id = nanoid()
  await env.DB.prepare(`
    INSERT INTO settlements (id, room_id, host_id, gross_amount, is_business)
    VALUES (?, ?, ?, ?, ?)
  `).bind(id, roomId, room.host_id, gross, room.is_business).run()
}
