-- Units (base units: g, ml, item)
create table if not exists public.units (
  code text primary key,                            -- e.g., g, kg, oz, lb, ml, l, tsp, tbsp, cup, item
  unit_type text not null check (unit_type in ('mass','volume','count')),
  ratio_to_base numeric not null                    -- mass→g, volume→ml, count→item
);

insert into public.units(code, unit_type, ratio_to_base) values
  ('g','mass',1), ('kg','mass',1000), ('oz','mass',28.349523125), ('lb','mass',453.59237),
  ('ml','volume',1), ('l','volume',1000), ('tsp','volume',4.92892), ('tbsp','volume',14.7868), ('cup','volume',236.588),
  ('item','count',1)
on conflict (code) do nothing;

-- Ingredient categories (flat or hierarchical)
create table if not exists public.ingredient_categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  parent_id uuid references public.ingredient_categories(id) on delete set null
);
