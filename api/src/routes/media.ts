import { Hono } from 'hono'
import { AppContext } from '../index'
import { nanoid } from '../utils/jwt'

export const mediaRoutes = new Hono<AppContext>()

// R2 presigned URL 발급 (영상/이미지 업로드용)
mediaRoutes.post('/presign', async (c) => {
  const userId = c.get('userId')
  const { type, ext } = await c.req.json<{ type: 'reel' | 'receipt' | 'avatar'; ext: string }>()

  if (!type || !ext) return c.json({ error: 'type, ext required' }, 400)
  const allowed = ['mp4', 'mov', 'jpg', 'jpeg', 'png', 'webp', 'heic', 'pdf']
  if (!allowed.includes(ext.toLowerCase())) return c.json({ error: 'Unsupported file type' }, 400)

  const MAX_SIZE: Record<string, number> = {
    reel: 50 * 1024 * 1024,    // 50MB (15초 영상)
    receipt: 10 * 1024 * 1024, // 10MB
    avatar: 5 * 1024 * 1024,   // 5MB
  }

  const key = `${type}/${userId}/${nanoid()}.${ext}`
  // R2 presigned URL (Workers에서는 createPresignedUrl 사용)
  // wrangler에서 MEDIA 바인딩이 있어야 동작
  const url = await (c.env.MEDIA as unknown as R2Bucket & {
    createPresignedUrl?: (key: string, opts: unknown) => Promise<string>
  }).createPresignedUrl?.(key, {
    expiresIn: 300,
    httpMethod: 'PUT',
    fields: { 'Content-Length': String(MAX_SIZE[type] ?? 10 * 1024 * 1024) },
  })

  const publicUrl = `https://media.dolunch.app/${key}`

  // createPresignedUrl이 없는 환경(로컬)에선 직접 업로드 엔드포인트 사용
  if (!url) {
    return c.json({ uploadUrl: `/api/media/upload/${key}`, key, method: 'PUT', publicUrl })
  }

  return c.json({ uploadUrl: url, key, publicUrl })
})

// 로컬/fallback 직접 업로드
mediaRoutes.put('/upload/:key{.+}', async (c) => {
  const key = c.req.param('key')
  const body = await c.req.arrayBuffer()
  await c.env.MEDIA.put(key, body)
  const publicUrl = `https://media.dolunch.app/${key}`
  return c.json({ url: publicUrl, key })
})
