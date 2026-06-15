-- =============================================
-- 점심어때 D1 Schema v1
-- =============================================

-- 유저 (호스트/게스트 겸용)
CREATE TABLE IF NOT EXISTS users (
  id           TEXT PRIMARY KEY,
  phone        TEXT UNIQUE,
  kakao_id     TEXT UNIQUE,
  name         TEXT NOT NULL,
  handle       TEXT UNIQUE NOT NULL,
  bio          TEXT DEFAULT '',
  avatar_url   TEXT,
  -- 사업자 여부 (정산 방식 결정)
  is_business  INTEGER NOT NULL DEFAULT 0,
  biz_reg_no   TEXT,     -- 사업자등록번호
  -- 통계 (비정규화 캐시)
  follower_count  INTEGER NOT NULL DEFAULT 0,
  hosting_count   INTEGER NOT NULL DEFAULT 0,
  rating          REAL NOT NULL DEFAULT 0.0,
  rating_count    INTEGER NOT NULL DEFAULT 0,
  created_at   TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at   TEXT NOT NULL DEFAULT (datetime('now'))
);

-- 팔로우
CREATE TABLE IF NOT EXISTS follows (
  follower_id  TEXT NOT NULL REFERENCES users(id),
  followee_id  TEXT NOT NULL REFERENCES users(id),
  created_at   TEXT NOT NULL DEFAULT (datetime('now')),
  PRIMARY KEY (follower_id, followee_id)
);

-- 숏츠 (15초 영상)
CREATE TABLE IF NOT EXISTS reels (
  id           TEXT PRIMARY KEY,
  host_id      TEXT NOT NULL REFERENCES users(id),
  video_url    TEXT NOT NULL,   -- R2 URL
  thumb_url    TEXT,
  caption      TEXT DEFAULT '',
  duration_sec INTEGER NOT NULL DEFAULT 15,
  like_count   INTEGER NOT NULL DEFAULT 0,
  comment_count INTEGER NOT NULL DEFAULT 0,
  is_active    INTEGER NOT NULL DEFAULT 1,
  created_at   TEXT NOT NULL DEFAULT (datetime('now'))
);

-- 숏츠 좋아요
CREATE TABLE IF NOT EXISTS reel_likes (
  reel_id   TEXT NOT NULL REFERENCES reels(id),
  user_id   TEXT NOT NULL REFERENCES users(id),
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  PRIMARY KEY (reel_id, user_id)
);

-- 방 (모임)
CREATE TABLE IF NOT EXISTS rooms (
  id           TEXT PRIMARY KEY,
  host_id      TEXT NOT NULL REFERENCES users(id),
  reel_id      TEXT REFERENCES reels(id),  -- 연결된 숏츠
  title        TEXT NOT NULL,
  description  TEXT DEFAULT '',
  menu         TEXT NOT NULL,
  place_name   TEXT NOT NULL,
  place_address TEXT,
  -- 일정
  meet_at      TEXT NOT NULL,   -- ISO8601
  -- 인원
  capacity     INTEGER NOT NULL DEFAULT 4,
  joined_count INTEGER NOT NULL DEFAULT 0,
  -- 금액 (원 단위)
  price_per_person  INTEGER NOT NULL,  -- 1인 총액 (호스트 설정)
  deposit_amount    INTEGER NOT NULL,  -- 보증금 = price_per_person * 0.20
  platform_fee      INTEGER NOT NULL,  -- price_per_person * 0.30
  host_revenue      INTEGER NOT NULL,  -- price_per_person * 0.70
  -- 상태: open | full | done | cancelled
  status       TEXT NOT NULL DEFAULT 'open',
  created_at   TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at   TEXT NOT NULL DEFAULT (datetime('now'))
);

-- 지원 (게스트 → 방)
CREATE TABLE IF NOT EXISTS applications (
  id           TEXT PRIMARY KEY,
  room_id      TEXT NOT NULL REFERENCES rooms(id),
  guest_id     TEXT NOT NULL REFERENCES users(id),
  -- 상태: pending | accepted | rejected | cancelled
  status       TEXT NOT NULL DEFAULT 'pending',
  -- 보증금 결제
  deposit_payment_key  TEXT,   -- Toss 결제키
  deposit_paid_at      TEXT,
  deposit_amount       INTEGER NOT NULL,
  -- 본결제
  main_payment_key     TEXT,
  main_paid_at         TEXT,
  main_amount          INTEGER NOT NULL,
  -- 출석
  attended     INTEGER,   -- NULL=미확인, 1=참석, 0=노쇼
  noshow_deducted INTEGER NOT NULL DEFAULT 0,  -- 노쇼 차감 여부
  created_at   TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at   TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE (room_id, guest_id)
);

-- 정산 (호스트 수익 지급)
CREATE TABLE IF NOT EXISTS settlements (
  id              TEXT PRIMARY KEY,
  room_id         TEXT NOT NULL REFERENCES rooms(id),
  host_id         TEXT NOT NULL REFERENCES users(id),
  -- 금액
  gross_amount    INTEGER NOT NULL,  -- 총 호스트 몫 (price*0.70*참석인원)
  restaurant_cost INTEGER,           -- 식당 실비 (영수증 등록 후 확정)
  net_profit      INTEGER,           -- gross - restaurant_cost
  -- 세금
  is_business     INTEGER NOT NULL DEFAULT 0,
  withholding_tax INTEGER,           -- 개인: net_profit * 0.033
  final_payout    INTEGER,           -- 실지급액
  -- 영수증
  receipt_url     TEXT,              -- R2 URL
  receipt_amount  INTEGER,
  receipt_verified INTEGER NOT NULL DEFAULT 0,
  -- 상태: pending | receipt_uploaded | processing | paid
  status          TEXT NOT NULL DEFAULT 'pending',
  paid_at         TEXT,
  created_at      TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

-- 결제 로그 (Toss 웹훅 원본 보존)
CREATE TABLE IF NOT EXISTS payment_logs (
  id           TEXT PRIMARY KEY,
  payment_key  TEXT NOT NULL,
  order_id     TEXT NOT NULL,
  type         TEXT NOT NULL,   -- deposit | main | refund | deduction
  amount       INTEGER NOT NULL,
  status       TEXT NOT NULL,   -- raw Toss status
  raw_json     TEXT NOT NULL,
  created_at   TEXT NOT NULL DEFAULT (datetime('now'))
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_reels_host ON reels(host_id);
CREATE INDEX IF NOT EXISTS idx_rooms_host ON rooms(host_id, status);
CREATE INDEX IF NOT EXISTS idx_rooms_status ON rooms(status, meet_at);
CREATE INDEX IF NOT EXISTS idx_applications_room ON applications(room_id, status);
CREATE INDEX IF NOT EXISTS idx_applications_guest ON applications(guest_id, status);
CREATE INDEX IF NOT EXISTS idx_settlements_host ON settlements(host_id, status);
CREATE INDEX IF NOT EXISTS idx_payment_logs_key ON payment_logs(payment_key);
