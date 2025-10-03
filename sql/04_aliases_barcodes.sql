-- Aliases / synonyms mapped to canonical ingredients
create table if not exists public.ingredient_aliases (
  id uuid primary key default gen_random_uuid(),
  ingredient_id uuid not null references public.ingredients(id) on delete cascade,
  alias text not null,
  normalized_alias text generated always as (lower(unaccent(alias))) stored,
  source text not null default 'user' check (source in ('system','user')),
  user_id uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

alter table public.ingredient_aliases enable row level security;

do $$
begin
  if exists (select 1 from pg_policies where schemaname='public' and tablename='ingredient_aliases' and policyname='alias_select_public_or_own') then
    drop policy "alias_select_public_or_own" on public.ingredient_aliases;
  end if;
  if exists (select 1 from pg_policies where schemaname='public' and tablename='ingredient_aliases' and policyname='alias_write_own') then
    drop policy "alias_write_own" on public.ingredient_aliases;
  end if;
end $$;

create policy "alias_select_public_or_own" on public.ingredient_aliases
for select
using (
  exists (
    select 1 from public.ingredients i
    where i.id = ingredient_aliases.ingredient_id
      and (i.visibility='public' or i.created_by = auth.uid())
  ) or user_id = auth.uid()
);

create policy "alias_write_own" on public.ingredient_aliases
for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Fuzzy search index
do $$
begin
  if not exists (
    select 1 from pg_indexes where schemaname='public' and indexname='ingredient_aliases_trgm_idx'
  ) then
    create index ingredient_aliases_trgm_idx
    on public.ingredient_aliases using gin (normalized_alias gin_trgm_ops);
  end if;
end $$;

-- Barcode mappings (UPC/EAN → ingredient)
create table if not exists public.barcode_mappings (
  upc text primary key,
  ingredient_id uuid not null references public.ingredients(id) on delete cascade,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);
alter table public.barcode_mappings enable row level security;

do $$
begin
  if exists (select 1 from pg_policies where schemaname='public' and tablename='barcode_mappings' and policyname='barcode_select_all') then
    drop policy "barcode_select_all" on public.barcode_mappings;
  end if;
  if exists (select 1 from pg_policies where schemaname='public' and tablename='barcode_mappings' and policyname='barcode_write_own') then
    drop policy "barcode_write_own" on public.barcode_mappings;
  end if;
end $$;

create policy "barcode_select_all" on public.barcode_mappings
for select using (true);

create policy "barcode_write_own" on public.barcode_mappings
for all using (created_by = auth.uid() or created_by is null)
with check (created_by = auth.uid());
