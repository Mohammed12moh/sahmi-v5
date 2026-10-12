-- ============================================================
-- سهمي (Sahmi) — إعداد قاعدة البيانات كاملاً (المراحل 1 → 4 + الدردشة)
-- شغّله مرة واحدة: Supabase → SQL Editor → New query → الصق → Run
-- آمن لإعادة التنفيذ. إذا ظهر تنبيه "destructive" اضغط Run this query.
-- ============================================================

-- سهمي - المرحلة 1 / Sahmi phase 1 schema (demo mode)
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text, username text unique not null, phone text,
  birth_date date, gender text, city text, district text, address text,
  invite_code text unique not null,
  invited_by uuid references public.profiles(id),
  demo_balance numeric(14,2) not null default 1000,  -- رصيد تجريبي فقط
  xp int not null default 0,
  is_banned boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

drop policy if exists "own profile read" on public.profiles;
create policy "own profile read" on public.profiles
  for select using (auth.uid() = id);

-- المستخدم يعدّل بياناته الشخصية فقط، وليس الرصيد/النقاط/الحظر
drop policy if exists "own profile update" on public.profiles;
create policy "own profile update" on public.profiles
  for update using (auth.uid() = id) with check (auth.uid() = id);
revoke update on public.profiles from authenticated;
grant update (full_name, phone, city, district, address) on public.profiles to authenticated;

create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
declare code text; inviter uuid;
begin
  loop
    code := upper(substr(md5(random()::text || new.id::text), 1, 8));
    exit when not exists (select 1 from profiles where invite_code = code);
  end loop;
  select id into inviter from profiles where invite_code = new.raw_user_meta_data->>'invited_by_code';
  insert into profiles (id, full_name, username, phone, birth_date, gender, city, district, address, invite_code, invited_by)
  values (new.id, new.raw_user_meta_data->>'full_name', lower(new.raw_user_meta_data->>'username'),
          new.raw_user_meta_data->>'phone', nullif(new.raw_user_meta_data->>'birth_date','')::timestamptz::date,
          new.raw_user_meta_data->>'gender', new.raw_user_meta_data->>'city',
          new.raw_user_meta_data->>'district', new.raw_user_meta_data->>'address', code, inviter);
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- فحص اسم المستخدم دون كشف بيانات / username check without exposing rows
create or replace function public.username_available(p_username text) returns boolean
language sql security definer set search_path = public stable as $$
  select not exists (select 1 from profiles where username = lower(p_username));
$$;

create or replace function public.invite_code_count(p_code text) returns int
language sql security definer set search_path = public stable as $$
  select count(*)::int from profiles where invited_by = (select id from profiles where invite_code = upper(p_code));
$$;
grant execute on function public.username_available(text), public.invite_code_count(text) to anon, authenticated;

-- ===== المرحلة 2 / Phase 2 =====
-- قائمة المراقبة / Watchlist (private per user)
create table if not exists public.watchlist (
  user_id uuid not null references auth.users(id) on delete cascade,
  symbol text not null,
  created_at timestamptz not null default now(),
  primary key (user_id, symbol)
);
alter table public.watchlist enable row level security;
drop policy if exists "own watchlist" on public.watchlist;
create policy "own watchlist" on public.watchlist
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- تحديث الرصيد فوراً (Realtime) / live balance updates
do $$ begin
  alter publication supabase_realtime add table public.profiles;
exception when duplicate_object then null; end $$;

-- ===== المرحلة 3 / Phase 3: شحن تجريبي + دعوات =====
-- سجل المعاملات (قراءة فقط للمستخدم؛ الكتابة عبر الدوال فقط)
create table if not exists public.transactions (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  type text not null check (type in ('demo_deposit','demo_bonus')),
  amount numeric(14,2) not null,
  note text,
  created_at timestamptz not null default now()
);
alter table public.transactions enable row level security;
drop policy if exists "own tx read" on public.transactions;
create policy "own tx read" on public.transactions for select using (auth.uid() = user_id);

create table if not exists public.xp_events (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  kind text not null,
  xp int not null,
  note text,
  created_at timestamptz not null default now()
);
alter table public.xp_events enable row level security;
drop policy if exists "own xp read" on public.xp_events;
create policy "own xp read" on public.xp_events for select using (auth.uid() = user_id);

-- شحن رصيد تجريبي (10-1000، حد 10 عمليات/يوم، هدية 5 عند 50+)
create or replace function public.demo_deposit(p_amount numeric) returns numeric
language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid(); bonus numeric := 0; todays int; newbal numeric;
begin
  if uid is null then raise exception 'not authenticated'; end if;
  if p_amount is null or p_amount < 10 or p_amount > 1000 then raise exception 'amount out of range'; end if;
  select count(*) into todays from transactions
    where user_id = uid and type = 'demo_deposit' and created_at > now() - interval '1 day';
  if todays >= 10 then raise exception 'daily demo limit reached'; end if;
  if p_amount >= 50 then bonus := 5; end if;
  update profiles set demo_balance = demo_balance + p_amount + bonus
    where id = uid and not is_banned returning demo_balance into newbal;
  if newbal is null then raise exception 'account unavailable'; end if;
  insert into transactions(user_id, type, amount, note) values (uid, 'demo_deposit', p_amount, 'شحن تجريبي');
  if bonus > 0 then
    insert into transactions(user_id, type, amount, note) values (uid, 'demo_bonus', bonus, 'هدية شحن 50+');
  end if;
  return newbal;
end $$;
revoke all on function public.demo_deposit(numeric) from public, anon;
grant execute on function public.demo_deposit(numeric) to authenticated;

-- نقاط XP لكل صديق حسب مستوى الداعي (برونز 5 | فضة 7 | ذهب 10 | بلاتين 15 | ماسي 20)
create or replace function public.referral_level_rate(cnt int) returns int
language sql immutable as $$
  select case when cnt >= 50 then 20 when cnt >= 30 then 15 when cnt >= 15 then 10 when cnt >= 5 then 7 else 5 end
$$;

create or replace function public.award_referral_xp() returns trigger
language plpgsql security definer set search_path = public as $$
declare cnt int; rate int;
begin
  if new.invited_by is null then return new; end if;
  select count(*) into cnt from profiles where invited_by = new.invited_by and id <> new.id;
  rate := referral_level_rate(cnt);
  update profiles set xp = xp + rate where id = new.invited_by;
  insert into xp_events(user_id, kind, xp, note) values (new.invited_by, 'referral_signup', rate, 'تسجيل صديق');
  return new;
end $$;
drop trigger if exists on_profile_referral on public.profiles;
create trigger on_profile_referral after insert on public.profiles
  for each row execute function public.award_referral_xp();

create or replace function public.my_referral_summary() returns json
language sql security definer set search_path = public stable as $$
  select json_build_object(
    'count', (select count(*) from profiles where invited_by = auth.uid()),
    'recent', coalesce((select json_agg(r) from (
        select username, created_at from profiles
        where invited_by = auth.uid() order by created_at desc limit 20) r), '[]'::json));
$$;

create or replace function public.referral_leaderboard(p_period text)
returns table(rank bigint, username text, invites bigint)
language sql security definer set search_path = public stable as $$
  select row_number() over (order by count(c.id) desc, min(c.created_at)) as rank, p.username, count(c.id) as invites
  from profiles p join profiles c on c.invited_by = p.id
  where p_period = 'all'
     or (p_period = 'week' and c.created_at > now() - interval '7 days')
     or (p_period = 'month' and c.created_at > now() - interval '30 days')
  group by p.id, p.username
  order by invites desc, min(c.created_at)
  limit 20;
$$;
revoke all on function public.my_referral_summary(), public.referral_leaderboard(text) from public, anon;
grant execute on function public.my_referral_summary(), public.referral_leaderboard(text) to authenticated;

-- ===== المرحلة 4 / Phase 4: محفظة + تداول تجريبي + تلعيب =====
alter table public.profiles
  add column if not exists streak int not null default 0,
  add column if not exists last_active date;

create table if not exists public.holdings (
  user_id uuid not null references auth.users(id) on delete cascade,
  symbol text not null,
  qty numeric(18,4) not null check (qty > 0),
  avg_price numeric(14,4) not null,
  primary key (user_id, symbol)
);
create table if not exists public.trades (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  symbol text not null,
  side text not null check (side in ('buy','sell')),
  qty numeric(18,4) not null,
  price numeric(14,4) not null,
  pnl numeric(14,2) not null default 0,
  created_at timestamptz not null default now()
);
create table if not exists public.user_badges (
  user_id uuid not null references auth.users(id) on delete cascade,
  badge text not null,
  earned_at timestamptz not null default now(),
  primary key (user_id, badge)
);
create table if not exists public.challenge_claims (
  user_id uuid not null references auth.users(id) on delete cascade,
  challenge_id text not null,
  period_key text not null,
  claimed_at timestamptz not null default now(),
  primary key (user_id, challenge_id, period_key)
);
alter table public.holdings enable row level security;
alter table public.trades enable row level security;
alter table public.user_badges enable row level security;
alter table public.challenge_claims enable row level security;
drop policy if exists "own holdings read" on public.holdings;
create policy "own holdings read" on public.holdings for select using (auth.uid() = user_id);
drop policy if exists "own trades read" on public.trades;
create policy "own trades read" on public.trades for select using (auth.uid() = user_id);
drop policy if exists "own badges read" on public.user_badges;
create policy "own badges read" on public.user_badges for select using (auth.uid() = user_id);
drop policy if exists "own claims read" on public.challenge_claims;
create policy "own claims read" on public.challenge_claims for select using (auth.uid() = user_id);

-- دخول يومي + Streak (+5 XP)
create or replace function public.touch_daily() returns int
language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid(); la date; st int;
begin
  if uid is null then raise exception 'not authenticated'; end if;
  select last_active, streak into la, st from profiles where id = uid;
  if la = current_date then return st; end if;
  if la = current_date - 1 then st := coalesce(st, 0) + 1; else st := 1; end if;
  update profiles set streak = st, last_active = current_date, xp = xp + 5 where id = uid;
  insert into xp_events(user_id, kind, xp, note) values (uid, 'daily', 5, 'دخول يومي');
  return st;
end $$;

-- الشارات (+20 XP لكل شارة جديدة)
create or replace function public.check_badges() returns json
language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid(); b text; newb text[] := '{}';
        trades_n int; profit_n int; refs int; watch_n int; st int;
begin
  if uid is null then raise exception 'not authenticated'; end if;
  select count(*) into trades_n from trades where user_id = uid;
  select count(*) into profit_n from trades where user_id = uid and side = 'sell' and pnl > 0;
  select count(*) into refs from profiles where invited_by = uid;
  select count(*) into watch_n from watchlist where user_id = uid;
  select streak into st from profiles where id = uid;
  for b in select unnest(array[
      case when trades_n >= 1 then 'first_trade' end,
      case when trades_n >= 10 then 'ten_trades' end,
      case when profit_n >= 1 then 'first_profit' end,
      case when st >= 3 then 'streak_3' end,
      case when st >= 7 then 'streak_7' end,
      case when refs >= 1 then 'first_referral' end,
      case when refs >= 5 then 'five_referrals' end,
      case when watch_n >= 5 then 'watchlist_5' end]) loop
    if b is not null then
      insert into user_badges(user_id, badge) values (uid, b) on conflict do nothing;
      if found then
        newb := newb || b;
        update profiles set xp = xp + 20 where id = uid;
        insert into xp_events(user_id, kind, xp, note) values (uid, 'badge', 20, b);
      end if;
    end if;
  end loop;
  return to_json(newb);
end $$;

-- تداول تجريبي: الرصيد افتراضي. ملاحظة: السعر يأتي من محاكاة العميل (للتجربة فقط)؛
-- في الإنتاج يجب أن يأتي السعر من الخادم/مصدر موثوق.
create or replace function public.execute_trade(p_symbol text, p_side text, p_qty numeric, p_price numeric)
returns json language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid(); bal numeric; hq numeric; hp numeric; cost numeric;
        pnl numeric := 0; nb json; sym text := upper(trim(p_symbol));
begin
  if uid is null then raise exception 'not authenticated'; end if;
  if sym !~ '^[A-Z]{1,6}$' then raise exception 'invalid symbol'; end if;
  if p_side not in ('buy','sell') then raise exception 'invalid side'; end if;
  if p_qty is null or p_qty <= 0 or p_qty > 100000 then raise exception 'invalid quantity'; end if;
  if p_price is null or p_price <= 0 or p_price > 1000000 then raise exception 'invalid price'; end if;
  select demo_balance into bal from profiles where id = uid and not is_banned for update;
  if bal is null then raise exception 'account unavailable'; end if;
  cost := round(p_qty * p_price, 2);
  select qty, avg_price into hq, hp from holdings where user_id = uid and symbol = sym for update;
  if p_side = 'buy' then
    if cost > bal then raise exception 'insufficient balance'; end if;
    if hq is null then
      insert into holdings(user_id, symbol, qty, avg_price) values (uid, sym, p_qty, p_price);
    else
      update holdings set avg_price = (hq * hp + p_qty * p_price) / (hq + p_qty), qty = hq + p_qty
        where user_id = uid and symbol = sym;
    end if;
    update profiles set demo_balance = demo_balance - cost where id = uid;
  else
    if hq is null or hq < p_qty then raise exception 'insufficient holdings'; end if;
    pnl := round((p_price - hp) * p_qty, 2);
    if hq = p_qty then
      delete from holdings where user_id = uid and symbol = sym;
    else
      update holdings set qty = hq - p_qty where user_id = uid and symbol = sym;
    end if;
    update profiles set demo_balance = demo_balance + cost where id = uid;
  end if;
  insert into trades(user_id, symbol, side, qty, price, pnl) values (uid, sym, p_side, p_qty, p_price, pnl);
  update profiles set xp = xp + 2 where id = uid;
  insert into xp_events(user_id, kind, xp, note) values (uid, 'trade', 2, sym);
  select demo_balance into bal from profiles where id = uid;
  nb := check_badges();
  return json_build_object('balance', bal, 'pnl', pnl, 'new_badges', nb);
end $$;

-- تقدم التحديات
create or replace function public.challenge_progress() returns json
language sql security definer set search_path = public stable as $$
  select json_build_object(
    'trades_today', (select count(*) from trades where user_id = auth.uid() and created_at >= date_trunc('day', now())),
    'trades_week', (select count(*) from trades where user_id = auth.uid() and created_at >= date_trunc('week', now())),
    'refs_week', (select count(*) from profiles where invited_by = auth.uid() and created_at >= date_trunc('week', now())),
    'opened_today', coalesce((select last_active = current_date from profiles where id = auth.uid()), false),
    'claimed', coalesce((select json_agg(challenge_id) from challenge_claims
        where user_id = auth.uid()
          and period_key in ('D' || current_date::text, 'W' || to_char(now(), 'IYYY-IW'))), '[]'::json));
$$;

-- استلام مكافأة تحدٍّ (يتحقق الخادم من الإنجاز ويمنع التكرار)
create or replace function public.claim_challenge(p_id text) returns int
language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid(); ok boolean; reward int; pkey text;
begin
  if uid is null then raise exception 'not authenticated'; end if;
  if p_id = 'daily_open' then
    select coalesce(last_active = current_date, false) into ok from profiles where id = uid;
    reward := 5; pkey := 'D' || current_date::text;
  elsif p_id = 'daily_trade' then
    select count(*) >= 1 into ok from trades where user_id = uid and created_at >= date_trunc('day', now());
    reward := 10; pkey := 'D' || current_date::text;
  elsif p_id = 'weekly_trades' then
    select count(*) >= 5 into ok from trades where user_id = uid and created_at >= date_trunc('week', now());
    reward := 40; pkey := 'W' || to_char(now(), 'IYYY-IW');
  elsif p_id = 'weekly_invite' then
    select count(*) >= 1 into ok from profiles where invited_by = uid and created_at >= date_trunc('week', now());
    reward := 50; pkey := 'W' || to_char(now(), 'IYYY-IW');
  else
    raise exception 'unknown challenge';
  end if;
  if ok is not true then raise exception 'not completed'; end if;
  insert into challenge_claims(user_id, challenge_id, period_key) values (uid, p_id, pkey);
  update profiles set xp = xp + reward where id = uid;
  insert into xp_events(user_id, kind, xp, note) values (uid, 'challenge', reward, p_id);
  return reward;
end $$;

revoke all on function public.touch_daily(), public.check_badges(), public.challenge_progress(),
  public.execute_trade(text, text, numeric, numeric), public.claim_challenge(text) from public, anon;
grant execute on function public.touch_daily(), public.check_badges(), public.challenge_progress(),
  public.execute_trade(text, text, numeric, numeric), public.claim_challenge(text) to authenticated;

-- ===== الدردشة: غرف + رسائل (آمن لإعادة التنفيذ، ويقوّي أي نسخة سابقة) =====
create table if not exists public.rooms (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);
alter table public.rooms alter column created_by drop not null;  -- الغرف النظامية بلا منشئ

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms(id) on delete cascade,
  user_id uuid not null references auth.users(id),
  content text not null,
  created_at timestamptz not null default now()
);
alter table public.messages add column if not exists username text;  -- يملأه التريغر
create index if not exists messages_room_id_created_at_idx on public.messages (room_id, created_at);

-- حد طول الرسالة (NOT VALID: لا يفحص الرسائل القديمة، يطبّق على الجديدة)
do $$ begin
  alter table public.messages add constraint messages_content_len
    check (char_length(content) between 1 and 500) not valid;
exception when duplicate_object then null; end $$;

alter table public.rooms enable row level security;
alter table public.messages enable row level security;

-- إزالة السياسات القديمة (كانت تسمح لأي مستخدم بإنشاء غرف)
drop policy if exists "rooms_select_authenticated" on public.rooms;
drop policy if exists "rooms_insert_authenticated" on public.rooms;
drop policy if exists "messages_select_authenticated" on public.messages;
drop policy if exists "messages_insert_own" on public.messages;
drop policy if exists "rooms_select" on public.rooms;
drop policy if exists "messages_select" on public.messages;
drop policy if exists "messages_insert" on public.messages;

-- الغرف: قراءة لكل مسجّل. الإنشاء للنظام/الأدمن فقط (لا سياسة إدخال للمستخدمين)
create policy "rooms_select" on public.rooms for select using (auth.uid() is not null);
-- الرسائل: قراءة لكل مسجّل، والإرسال باسمك فقط وغير محظور
create policy "messages_select" on public.messages for select using (auth.uid() is not null);
create policy "messages_insert" on public.messages for insert with check (
  auth.uid() = user_id
  and not exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_banned)
);

revoke all on public.rooms, public.messages from anon;
revoke insert, update, delete on public.rooms from authenticated;
revoke update, delete on public.messages from authenticated;

-- قبل الإدخال: تنظيف النص + حد 20 رسالة/دقيقة + تعبئة اسم المستخدم
create or replace function public.messages_before_insert() returns trigger
language plpgsql security definer set search_path = public as $$
declare n int;
begin
  new.content := btrim(new.content);
  if new.content = '' then raise exception 'empty message'; end if;
  select count(*) into n from messages
    where user_id = new.user_id and created_at > now() - interval '1 minute';
  if n >= 20 then raise exception 'rate limit'; end if;
  select username into new.username from profiles where id = new.user_id;
  return new;
end $$;
drop trigger if exists messages_before_insert on public.messages;
create trigger messages_before_insert before insert on public.messages
  for each row execute function public.messages_before_insert();

-- غرف افتراضية
insert into public.rooms (name, description)
select v.name, v.description
from (values
  ('عام', 'نقاش عام عن التداول والتطبيق'),
  ('الإشارات', 'ناقش إشارات الأسهم'),
  ('المبتدئين', 'أسئلة وتعلّم للمبتدئين')
) as v(name, description)
where not exists (select 1 from public.rooms r where r.name = v.name);

-- Realtime للرسائل
do $$ begin
  alter publication supabase_realtime add table public.messages;
exception when duplicate_object then null; end $$;

-- ===== تحقق: لازم يطلع 10 جداول وكلها rls_enabled = true =====
select c.relname as table_name, c.relrowsecurity as rls_enabled
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public' and c.relkind = 'r'
  and c.relname in ('profiles','watchlist','transactions','xp_events','holdings','trades','user_badges','challenge_claims','rooms','messages')
order by 1;
