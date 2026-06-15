const BASE = import.meta.env.VITE_API_URL ?? 'http://localhost:8787'

function getToken() {
  return localStorage.getItem('admin_token') ?? ''
}

export async function adminLogin(username: string, password: string): Promise<string> {
  const res = await fetch(`${BASE}/admin/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username, password }),
  })
  if (!res.ok) {
    const err = await res.json().catch(() => ({})) as { error?: string }
    throw new Error(err.error ?? '로그인에 실패했습니다.')
  }
  const { token } = await res.json() as { token: string }
  return token
}

async function req<T>(path: string, init?: RequestInit): Promise<T> {
  const res = await fetch(`${BASE}${path}`, {
    ...init,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${getToken()}`,
      ...init?.headers,
    },
  })
  if (res.status === 403) {
    localStorage.removeItem('admin_token')
    window.location.href = '/login'
    throw new Error('Unauthorized')
  }
  if (!res.ok) {
    const err = await res.json().catch(() => ({}))
    throw new Error((err as { error?: string }).error ?? `HTTP ${res.status}`)
  }
  return res.json() as Promise<T>
}

export const api = {
  // stats
  stats: () => req<AdminStats>('/admin/stats'),
  revenueDaily: () => req<{ data: DailyRevenue[] }>('/admin/stats/revenue-daily'),

  // users
  users: (params?: { q?: string; sort?: string; offset?: number }) =>
    req<{ users: AdminUser[]; total: number }>(`/admin/users?${new URLSearchParams(params as Record<string, string> ?? {})}` ),
  user: (id: string) => req<{ user: AdminUser; rooms: Room[]; applications: Application[] }>(`/admin/users/${id}`),
  patchUser: (id: string, body: Partial<AdminUser>) =>
    req<{ ok: boolean }>(`/admin/users/${id}`, { method: 'PATCH', body: JSON.stringify(body) }),

  // rooms
  rooms: (params?: { status?: string; q?: string }) =>
    req<{ rooms: Room[] }>(`/admin/rooms?${new URLSearchParams(params as Record<string, string> ?? {})}`),
  cancelRoom: (id: string, reason: string) =>
    req<{ ok: boolean; refunded: number }>(`/admin/rooms/${id}/cancel`, { method: 'PATCH', body: JSON.stringify({ reason }) }),

  // settlements
  settlements: (status?: string) =>
    req<{ settlements: Settlement[] }>(`/admin/settlements${status ? `?status=${status}` : ''}`),
  approveSettlement: (id: string) =>
    req<{ ok: boolean; finalPayout: number }>(`/admin/settlements/${id}/approve`, { method: 'PATCH', body: '{}' }),
  rejectSettlement: (id: string, reason: string) =>
    req<{ ok: boolean }>(`/admin/settlements/${id}/reject`, { method: 'PATCH', body: JSON.stringify({ reason }) }),
  markPaid: (id: string) =>
    req<{ ok: boolean }>(`/admin/settlements/${id}/paid`, { method: 'PATCH', body: '{}' }),

  // payments
  payments: (type?: string) =>
    req<{ payments: PaymentLog[] }>(`/admin/payments${type ? `?type=${type}` : ''}`),
  refund: (paymentKey: string, amount: number, reason: string) =>
    req<{ ok: boolean }>('/admin/payments/refund', { method: 'POST', body: JSON.stringify({ paymentKey, amount, reason }) }),

  // applications
  noshow: (id: string) => req<{ ok: boolean; deducted: number }>(`/admin/applications/${id}/noshow`, { method: 'POST', body: '{}' }),
  attend: (id: string) => req<{ ok: boolean }>(`/admin/applications/${id}/attend`, { method: 'POST', body: '{}' }),
}

// ─── Types ─────────────────────────────────────────────────────────
export type AdminStats = {
  users: { total: number; newToday: number }
  rooms: { total: number; open: number; done: number }
  applications: { total: number; pending: number }
  settlements: { pending: number; receiptReady: number }
  revenue: { total: number; today: number }
  attendance: { noShow: number; attended: number; noShowRate: number }
  deposits: { held: number }
}

export type DailyRevenue = { day: string; revenue: number; rooms: number }

export type AdminUser = {
  id: string; name: string; handle: string; phone?: string
  kakao_id?: string; is_business: number; biz_reg_no?: string
  follower_count: number; hosting_count: number; rating: number
  created_at: string; room_count?: number; apply_count?: number; total_spent?: number
}

export type Room = {
  id: string; title: string; status: string; meet_at: string
  place_name: string; menu: string; capacity: number; joined_count: number
  price_per_person: number; deposit_amount: number; platform_fee: number; host_revenue: number
  host_name?: string; host_handle?: string; created_at: string
}

export type Settlement = {
  id: string; room_id: string; host_id: string; status: string
  gross_amount: number; restaurant_cost?: number; net_profit?: number
  withholding_tax?: number; final_payout?: number
  is_business: number; biz_reg_no?: string
  receipt_url?: string; receipt_amount?: number; receipt_verified: number
  host_name: string; host_handle: string; room_title: string; meet_at: string
  joined_count: number; created_at: string; paid_at?: string
}

export type PaymentLog = {
  id: string; payment_key: string; order_id: string; type: string
  amount: number; status: string; created_at: string
}

export type Application = {
  id: string; room_id: string; guest_id: string; status: string
  deposit_amount: number; main_amount: number; attended: number | null
  deposit_payment_key?: string; main_payment_key?: string; noshow_deducted: number
  created_at: string; room_title?: string
}
