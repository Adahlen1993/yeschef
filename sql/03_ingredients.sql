-- Canonical ingredients
create table if not exists public.ingredients (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  normalized_name text generated always as (lower(unaccent(name))) stored,
  category_id uuid references public.ingredient_categories(id) on delete set null,
  default_unit text references public.units(code),
  visibility text not null default 'public' check (visibility in ('public','private')),
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

alter table public.ingredients enable row level security;

-- RLS policies (recreate idempotently)
do $$
begin
  if exists (select 1 from pg_policies where schemaname='public' and tablename='ingredients' and policyname='ingredients_select_public_or_own') then
    drop policy "ingredients_select_public_or_own" on public.ingredients;
  end if;
  if exists (select 1 from pg_policies where schemaname='public' and tablename='ingredients' and policyname='ingredients_write_own') then
    drop policy "ingredients_write_own" on public.ingredients;
  end if;
end $$;

create policy "ingredients_select_public_or_own" on public.ingredients
for select using (visibility='public' or created_by = auth.uid());

create policy "ingredients_write_own" on public.ingredients
for all using (created_by = auth.uid() or created_by is null)
with check (created_by = auth.uid());

-- Unique public normalized name (avoid dupes)
do $$
begin
  if not exists (
    select 1 from pg_indexes where schemaname='public' and indexname='ingredients_unique_public_normalized_name_idx'
  ) then
    create unique index ingredients_unique_public_normalized_name_idx
      on public.ingredients (normalized_name)
      where visibility='public';
  end if;
end $$;

-- Fuzzy search index
do $$
begin
  if not exists (
    select 1 from pg_indexes where schemaname='public' and indexname='ingredients_trgm_idx'
  ) then
    create index ingredients_trgm_idx on public.ingredients using gin (normalized_name gin_trgm_ops);
  end if;
end $$;

-- Per-ingredient unit/density hints (for conversions)
create table if not exists public.ingredient_units (
  id uuid primary key default gen_random_uuid(),
  ingredient_id uuid not null references public.ingredients(id) on delete cascade,
  preferred_unit text references public.units(code),
  density_g_per_ml numeric,                          -- for volume↔mass conversions (nullable)
  unit_conversions jsonb default '{}'::jsonb
);
