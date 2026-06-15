export async function signJwt(payload: Record<string, unknown>, secret: string, expiresInSec = 60 * 60 * 24 * 30): Promise<string> {
  const header = btoa(JSON.stringify({ alg: 'HS256', typ: 'JWT' }))
  const body = btoa(JSON.stringify({ ...payload, exp: Math.floor(Date.now() / 1000) + expiresInSec }))
  const encoder = new TextEncoder()
  const key = await crypto.subtle.importKey(
    'raw', encoder.encode(secret),
    { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']
  )
  const sig = await crypto.subtle.sign('HMAC', key, encoder.encode(`${header}.${body}`))
  const sigB64 = btoa(String.fromCharCode(...new Uint8Array(sig)))
  return `${header}.${body}.${sigB64}`
}

export function nanoid(len = 21): string {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
  return Array.from(crypto.getRandomValues(new Uint8Array(len)))
    .map((b) => chars[b % chars.length])
    .join('')
}

export function calcPricing(pricePerPerson: number, depositRatio: number, platformFeeRatio: number) {
  const deposit = Math.ceil(pricePerPerson * depositRatio)
  const platformFee = Math.ceil(pricePerPerson * platformFeeRatio)
  const hostRevenue = pricePerPerson - platformFee
  return { deposit, platformFee, hostRevenue }
}
