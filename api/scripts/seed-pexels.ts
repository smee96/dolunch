/**
 * Pexels 음식 영상으로 피드 시드 데이터 생성
 *
 * 사용법:
 *   PEXELS_API_KEY=xxx WRANGLER_ENV=prod npx tsx scripts/seed-pexels.ts
 *
 * Pexels API Key: https://www.pexels.com/api/
 * (무료, 상업 이용 허가)
 */

const PEXELS_KEY = process.env.PEXELS_API_KEY
const ENV = process.env.WRANGLER_ENV ?? 'prod'  // 'prod' | 'dev'
const DB_NAME = ENV === 'dev' ? 'dolunch-db-dev' : 'dolunch-db'

if (!PEXELS_KEY) {
  console.error('PEXELS_API_KEY 환경변수가 필요합니다.')
  console.error('https://www.pexels.com/api/ 에서 무료 발급 후:')
  console.error('  PEXELS_API_KEY=your_key npx tsx scripts/seed-pexels.ts')
  process.exit(1)
}

const QUERIES = ['food dining', 'restaurant meal', 'lunch dinner', 'cooking chef', 'coffee cafe']
const SEED_HOST_ID = 'dev_user_001'  // dev-login으로 생성된 유저

interface PexelsVideo {
  id: number
  url: string
  video_files: { link: string; quality: string; file_type: string; width: number; height: number }[]
  video_pictures: { picture: string; nr: number }[]
  duration: number
  user: { name: string; url: string }
}

interface PexelsResponse {
  videos: PexelsVideo[]
  total_results: number
}

async function fetchVideos(query: string, perPage = 5): Promise<PexelsVideo[]> {
  const res = await fetch(
    `https://api.pexels.com/videos/search?query=${encodeURIComponent(query)}&per_page=${perPage}&orientation=portrait&size=small`,
    { headers: { Authorization: PEXELS_KEY! } }
  )
  if (!res.ok) throw new Error(`Pexels API error: ${res.status}`)
  const data = await res.json() as PexelsResponse
  return data.videos
}

function getBestVideoUrl(video: PexelsVideo): string {
  // SD 또는 HD 우선 (용량 작은 것)
  const preferred = video.video_files
    .filter(f => f.file_type === 'video/mp4')
    .sort((a, b) => {
      const order = ['sd', 'hd', 'uhd']
      return order.indexOf(a.quality) - order.indexOf(b.quality)
    })
  return preferred[0]?.link ?? video.video_files[0]?.link ?? ''
}

function nanoid(len = 21): string {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
  return Array.from({ length: len }, () => chars[Math.floor(Math.random() * chars.length)]).join('')
}

const CAPTIONS = [
  '오늘 점심, 이 자리에 함께 하실 분 모십니다 🍽️',
  '특별한 한 끼의 시작. 의미있는 대화를 나눠요.',
  '좋은 음식엔 좋은 사람이 필요합니다.',
  '이 모임의 주인공이 되어보세요.',
  '매주 목요일 점심, 새로운 인연을 만나요.',
  '미쉐린 셰프가 추천한 곳에서 함께해요.',
  '잊지 못할 점심 경험. 자리가 얼마 남지 않았어요.',
  '서울 한복판, 숨겨진 맛집에서의 비밀 모임.',
  '당신의 다음 비즈니스 파트너를 이 자리에서.',
  '단 네 명만을 위한 특별 코스 런치.',
]

async function main() {
  console.log(`\n🎬 Pexels 시드 데이터 생성 시작 (DB: ${DB_NAME})\n`)

  const allVideos: PexelsVideo[] = []
  for (const query of QUERIES) {
    console.log(`  🔍 "${query}" 검색 중...`)
    const videos = await fetchVideos(query, 4)
    allVideos.push(...videos)
    await new Promise(r => setTimeout(r, 200)) // rate limit
  }

  // 중복 제거
  const unique = [...new Map(allVideos.map(v => [v.id, v])).values()]
  console.log(`\n  ✅ 총 ${unique.length}개 영상 수집\n`)

  const sqls: string[] = []

  for (let i = 0; i < unique.length; i++) {
    const v = unique[i]
    const videoUrl = getBestVideoUrl(v)
    const thumbUrl = v.video_pictures[0]?.picture ?? ''
    if (!videoUrl) continue

    const id = nanoid()
    const caption = CAPTIONS[i % CAPTIONS.length]

    sqls.push(
      `INSERT OR IGNORE INTO reels (id, host_id, video_url, thumb_url, caption, duration_sec, like_count, comment_count) ` +
      `VALUES ('${id}', '${SEED_HOST_ID}', '${videoUrl}', '${thumbUrl}', '${caption.replace(/'/g, "''")}', ${Math.min(v.duration, 15)}, ${Math.floor(Math.random() * 200)}, ${Math.floor(Math.random() * 20)});`
    )
  }

  if (sqls.length === 0) {
    console.log('⚠️  삽입할 영상이 없습니다.')
    return
  }

  // wrangler d1 execute로 삽입
  const { execSync } = await import('child_process')
  const dbFlag = ENV === 'dev' ? '--env dev' : ''

  for (const sql of sqls) {
    try {
      execSync(
        `npx wrangler d1 execute ${DB_NAME} --remote ${dbFlag} --command "${sql.replace(/"/g, '\\"')}"`,
        { stdio: 'pipe', cwd: process.cwd() }
      )
      process.stdout.write('.')
    } catch (e) {
      process.stdout.write('x')
    }
  }

  console.log(`\n\n✅ ${sqls.length}개 릴 삽입 완료! 앱에서 피드를 확인해 보세요.\n`)
}

main().catch(console.error)
