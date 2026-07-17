-- ============================================================
-- 第二階段：帳號與每人獨立雲端資料
-- 貼到 Supabase SQL Editor 執行一次（重複執行也安全）
-- ============================================================

-- 每位使用者一列，data 放整份 profile JSON；
-- RLS 保證「只有登入這個帳號的人」讀寫得到自己的資料
create table if not exists user_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

alter table user_profiles enable row level security;

drop policy if exists "own profile select" on user_profiles;
create policy "own profile select" on user_profiles
  for select using (auth.uid() = user_id);

drop policy if exists "own profile insert" on user_profiles;
create policy "own profile insert" on user_profiles
  for insert with check (auth.uid() = user_id);

drop policy if exists "own profile update" on user_profiles;
create policy "own profile update" on user_profiles
  for update using (auth.uid() = user_id);

-- 使用者有權刪掉自己的雲端資料（對應「刪除與匯出」治理要求）
drop policy if exists "own profile delete" on user_profiles;
create policy "own profile delete" on user_profiles
  for delete using (auth.uid() = user_id);

-- ============================================================
-- 另外兩件要在 Supabase 後台（不是 SQL）確認的事：
-- 1. Authentication → Providers → Email：確認是啟用的（預設就是）
-- 2. Authentication → Providers → Email → Confirm email：
--    測試期建議「關閉」，註冊完就能直接登入，不用先收確認信；
--    正式開放前再打開
-- ============================================================
