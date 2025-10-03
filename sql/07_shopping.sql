-- Shopping lists
create table if not exists public.shopping_lists (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'active' check (status in ('active','archived')),
  created_at timestamptz not null default now()
);
alter table public.shopping_lists enable row level security;

do $$
begin
  if exists (select 1 from pg_policies where schemaname='public' and tablename='shopping_lists' and policyname='shopping_lists_rw_own') then
    drop policy "shopping_lists_rw_own" on public.shopping_lists;
  end if;
end $$;
create policy "shopping_lists_rw_own" on public.shopping_lists
for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Shopping list items (dedup logic via unique partial indexes)
create table if not exists public.shopping_list_items (
  id uuid primary key default gen_random_uuid(),
  shopping_list_id uuid not null references public.shopping_lists(id) on delete cascade,
  ingredient_id uuid references public.ingredients(id),
  name_override text,
  quantity numeric not null default 1,
  unit text not null default 'item' references public.units(code),
  added_from text not null default 'manual' check (added_from in ('manual','recipe','low_stock','cook_out')),
  created_at timestamptz not null default now()
);
alter table public.shopping_list_items enable row level security;

do $$
begin
  if exists (select 1 from pg_policies where schemaname='public' and tablename='shopping_list_items' and policyname='shopping_items_rw_own') then
    drop policy "shopping_items_rw_own" on public.shopping_list_items;
  end if;
end $$;
create policy "shopping_items_rw_own" on public.shopping_list_items
for all using (
  auth.uid() = (
    select sl.user_id from public.shopping_lists sl where sl.id = shopping_list_items.shopping_list_id
  )
) with check (
  auth.uid() = (
    select sl.user_id from public.shopping_lists sl where sl.id = shopping_list_items.shopping_list_id
  )
);

-- Deduplicate by ingredient+unit when ingredient_id present
do $$
begin
  if not exists (select 1 from pg_indexes where schemaname='public' and indexname='shopping_items_unique_ing_unit_partial') then
    create unique index shopping_items_unique_ing_unit_partial
      on public.shopping_list_items (shopping_list_id, ingredient_id, unit)
      where ingredient_id is not null;
  end if;
end $$;

-- Deduplicate by normalized name+unit when ingredient_id is null
do $$
begin
  if not exists (select 1 from pg_indexes where schemaname='public' and indexname='shopping_items_unique_name_unit_partial') then
    create unique index shopping_items_unique_name_unit_partial
      on public.shopping_list_items (shopping_list_id, (lower(unaccent(name_override))), unit)
      where ingredient_id is null and name_override is not null;
  end if;
end $$;
