-- Receipts (OCR import)
create table if not exists public.receipts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  vendor text,
  purchased_at timestamptz,
  subtotal numeric, tax numeric, total numeric,
  raw_text text,
  status text not null default 'parsed' check (status in ('parsed','needs_review')),
  ocr_confidence numeric,
  created_at timestamptz not null default now()
);
alter table public.receipts enable row level security;
do $$
begin
  if exists (select 1 from pg_policies where schemaname='public' and tablename='receipts' and policyname='receipts_rw_own') then
    drop policy "receipts_rw_own" on public.receipts;
  end if;
end $$;
create policy "receipts_rw_own" on public.receipts
for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create table if not exists public.receipt_items (
  id uuid primary key default gen_random_uuid(),
  receipt_id uuid not null references public.receipts(id) on delete cascade,
  line_text text,
  upc text,
  ingredient_id uuid references public.ingredients(id),
  quantity numeric,
  unit text references public.units(code),
  price_each numeric,
  line_total numeric,
  confidence numeric,
  mapping_status text not null default 'auto' check (mapping_status in ('auto','manual','uncertain'))
);
