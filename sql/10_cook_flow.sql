-- Cook sessions
create table if not exists public.cook_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  recipe_id uuid not null references public.recipes(id) on delete cascade,
  chosen_servings int,
  used_basics boolean default true,
  started_at timestamptz not null default now(),
  finished_at timestamptz
);
alter table public.cook_sessions enable row level security;
do $$
begin
  if exists (select 1 from pg_policies where schemaname='public' and tablename='cook_sessions' and policyname='cook_sessions_rw_own') then
    drop policy "cook_sessions_rw_own" on public.cook_sessions;
  end if;
end $$;
create policy "cook_sessions_rw_own" on public.cook_sessions
for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create table if not exists public.cook_session_steps (
  id uuid primary key default gen_random_uuid(),
  cook_session_id uuid not null references public.cook_sessions(id) on delete cascade,
  step_number int not null,
  started_at timestamptz,
  finished_at timestamptz
);
create index if not exists cook_session_steps_order_idx on public.cook_session_steps (cook_session_id, step_number);

create table if not exists public.cook_session_consumption (
  id uuid primary key default gen_random_uuid(),
  cook_session_id uuid not null references public.cook_sessions(id) on delete cascade,
  ingredient_id uuid not null references public.ingredients(id),
  amount_used numeric not null,
  unit text not null references public.units(code),
  source text not null default 'scaled_from_recipe' check (source in ('direct','scaled_from_recipe'))
);
