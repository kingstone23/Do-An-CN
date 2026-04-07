-- ============================================================
-- DEPRECATED — Ứng dụng đã chuyển sang MongoDB + API Node + Clerk.
-- Giữ file này chỉ để tham chiếu lịch sử / migrate dữ liệu thủ công.
-- ============================================================
-- Harvest & Hearth — Supabase Schema (legacy)
-- ============================================================

-- ── Tables ───────────────────────────────────────────────────

CREATE TABLE profiles (
  id         UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  email      TEXT,
  name       TEXT,
  language   TEXT NOT NULL DEFAULT 'VIE',
  is_dark    BOOLEAN NOT NULL DEFAULT FALSE,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE food_items (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  name         TEXT NOT NULL,
  category     TEXT NOT NULL,
  storage      TEXT NOT NULL,
  quantity     FLOAT NOT NULL,
  unit         TEXT NOT NULL,
  added_date   TIMESTAMPTZ NOT NULL,
  expiry_date  TIMESTAMPTZ,
  warning_days INT,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE saved_recipes (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  original_id TEXT NOT NULL,
  recipe_data JSONB NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, original_id)
);

-- ── Row Level Security ────────────────────────────────────────

ALTER TABLE profiles      ENABLE ROW LEVEL SECURITY;
ALTER TABLE food_items    ENABLE ROW LEVEL SECURITY;
ALTER TABLE saved_recipes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "own profiles"      ON profiles      FOR ALL USING (auth.uid() = id);
CREATE POLICY "own food_items"    ON food_items    FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "own saved_recipes" ON saved_recipes FOR ALL USING (auth.uid() = user_id);
