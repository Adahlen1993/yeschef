-- Profiles mirror for auth.users
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  display_name text
);

alter table public.profiles enable row level security;

do $$
begin
  if exists (select 1 from pg_policies where schemaname='public' and tablename='profiles' and policyname='profiles_select_own') then
    drop policy "profiles_select_own" on public.profiles;
  end if;
  if exists (select 1 from pg_policies where schemaname='public' and tablename='profiles' and policyname='profiles_update_own') then
    drop policy "profiles_update_own" on public.profiles;
  end if;
end $$;

create policy "profiles_select_own" on public.profiles
for select using (auth.uid() = id);

create policy "profiles_update_own" on public.profiles
for update using (auth.uid() = id) with check (auth.uid() = id);

-- Auto-create a profile on signup
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id) values (new.id)
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- User settings (servings, diet, basics, etc.)
create table if not exists public.user_settings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  default_servings int default 2,
  dietary_preferences jsonb default '{}'::jsonb,
  cuisines_preferences jsonb default '{}'::jsonb,
  suggest_public_recipes boolean default true,
  always_include_basics boolean default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.user_settings enable row level security;

do $$
begin
  if exists (select 1 from pg_policies where schemaname='public' and tablename='user_settings' and policyname='user_settings_rw_own') then
    drop policy "user_settings_rw_own" on public.user_settings;
  end if;
end $$;

create policy "user_settings_rw_own" on public.user_settings
for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end; $$;

drop trigger if exists trg_user_settings_touch on public.user_settings;
create trigger trg_user_settings_touch before update on public.user_settings
for each row execute procedure public.touch_updated_at();

-- Optional addresses
create table if not exists public.user_addresses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  label text,
  line1 text, line2 text, city text, region text, postal_code text, country text,
  phone text,
  is_default boolean default false,
  created_at timestamptz not null default now()
);
alter table public.user_addresses enable row level security;

do $$
begin
  if exists (select 1 from pg_policies where schemaname='public' and tablename='user_addresses' and policyname='user_addresses_rw_own') then
    drop policy "user_addresses_rw_own" on public.user_addresses;
  end if;
end $$;
create policy "user_addresses_rw_own" on public.user_addresses
for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
