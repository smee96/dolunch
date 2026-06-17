CREATE TABLE IF NOT EXISTS comments (
  id TEXT PRIMARY KEY,
  reel_id TEXT NOT NULL REFERENCES reels(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL REFERENCES users(id),
  body TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
