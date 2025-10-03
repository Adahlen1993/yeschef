-- User-submitted ingredient proposals (for admin review)
create table if not exists public.user_ingredient_submissions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  proposed_name text not null,
  upc text,
  category_id uuid references public.ingredient_categories(id),
  notes text,
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  decided_by uuid references public.profiles(id),
  decided_at timestamptz,
  created_at timestamptz not null default now()
);
alter table public.user_ingredient_submissions enable row level security;
do $$
begin
  if exists (select 1 from pg_policies where schemaname='public' and tablename='user_ingredient_submissions' and policyname='user_ing_submissions_rw_own') then
    drop policy "user_ing_submissions_rw_own" on public.user_ingredient_submissions;
  end if;
end $$;
create policy "user_ing_submissions_rw_own" on public.user_ingredient_submissions
for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- User-submitted public recipes
create table if not exists public.user_recipe_submissions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  payload jsonb not null default '{}'::jsonb,    -- raw submitted recipe content
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  decided_by uuid references public.profiles(id),
  decided_at timestamptz,
  created_at timestamptz not null default now()
);
alter table public.user_recipe_submissions enable row level security;
do $$
begin
  if exists (select 1 from pg_policies where schemaname='public' and tablename='user_recipe_submissions' and policyname='user_recipe_submissions_rw_own') then
    drop policy "user_recipe_submissions_rw_own" on public.user_recipe_submissions;
  end if;
end $$;
create policy "user_recipe_submissions_rw_own" on public.user_recipe_submissions
for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Generic admin review queue (you can tie this to a role later)
create table if not exists public.admin_reviews (
  id uuid primary key default gen_random_uuid(),
  entity_type text not null check (entity_type in ('ingredient','recipe','barcode')),
  entity_id uuid not null,
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  reviewer_id uuid references public.profiles(id),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
