-- Pantry inventory
create table if not exists public.pantry_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  ingredient_id uuid references public.ingredients(id),
  name_override text,
  quantity numeric not null default 1,
  unit text not null default 'item' references public.units(code),
  added_via text not null default 'manual' check (added_via in ('manual','barcode','receipt')),
  reorder_threshold numeric,                         -- optional low-stock threshold
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.pantry_items enable row level security;

do $$
begin
  if exists (select 1 from pg_policies where schemaname='public' and tablename='pantry_items' and policyname='pantry_select_own') then
    drop policy "pantry_select_own" on public.pantry_items;
  end if;
  if exists (select 1 from pg_policies where schemaname='public' and tablename='pantry_items' and policyname='pantry_insert_own') then
    drop policy "pantry_insert_own" on public.pantry_items;
  end if;
  if exists (select 1 from pg_policies where schemaname='public' and tablename='pantry_items' and policyname='pantry_update_own') then
    drop policy "pantry_update_own" on public.pantry_items;
  end if;
  if exists (select 1 from pg_policies where schemaname='public' and tablename='pantry_items' and policyname='pantry_delete_own') then
    drop policy "pantry_delete_own" on public.pantry_items;
  end if;
end $$;

create policy "pantry_select_own" on public.pantry_items
for select using (auth.uid() = user_id);

create policy "pantry_insert_own" on public.pantry_items
for insert with check (auth.uid() = user_id);

create policy "pantry_update_own" on public.pantry_items
for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "pantry_delete_own" on public.pantry_items
for delete using (auth.uid() = user_id);

-- updated_at trigger
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end; $$;

drop trigger if exists trg_pantry_items_touch on public.pantry_items;
create trigger trg_pantry_items_touch
before update on public.pantry_items
for each row execute procedure public.set_updated_at();

-- Audit trail for inventory changes
create table if not exists public.pantry_transactions (
  id uuid primary key default gen_random_uuid(),
  pantry_item_id uuid references public.pantry_items(id) on delete set null,
  user_id uuid not null references public.profiles(id) on delete cascade,
  change_qty numeric not null,                        -- positive add / negative consume
  unit text not null references public.units(code),
  reason text not null check (reason in ('add','cook','adjust','receipt_import')),
  related_id uuid,                                    -- cook_session_id or receipt_id
  created_at timestamptz not null default now()
);
alter table public.pantry_transactions enable row level security;

do $$
begin
  if exists (select 1 from pg_policies where schemaname='public' and tablename='pantry_transactions' and policyname='pantry_txn_rw_own') then
    drop policy "pantry_txn_rw_own" on public.pantry_transactions;
  end if;
end $$;

create policy "pantry_txn_rw_own" on public.pantry_transactions
for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Always-have basics per user
create table if not exists public.user_basics (
  user_id uuid not null references public.profiles(id) on delete cascade,
  ingredient_id uuid not null references public.ingredients(id) on delete cascade,
  primary key (user_id, ingredient_id)
);
alter table public.user_basics enable row level security;
do $$
begin
  if exists (select 1 from pg_policies where schemaname='public' and tablename='user_basics' and policyname='user_basics_rw_own') then
    drop policy "user_basics_rw_own" on public.user_basics;
  end if;
end $$;
create policy "user_basics_rw_own" on public.user_basics
for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Helpful indexes
create index if not exists pantry_items_user_updated_idx on public.pantry_items (user_id, updated_at desc);
create index if not exists pantry_items_ingredient_idx on public.pantry_items (ingredient_id);
