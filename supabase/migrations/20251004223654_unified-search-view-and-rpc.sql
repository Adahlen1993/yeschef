-- Normalizer
create or replace function norm(txt text) returns text
language sql immutable as $$
  select lower(trim(txt))
$$;

-- Unified search (global + personal)
create or replace view ingredient_search_entries as
select
  g.id::bigint    as row_id,
  g.name          as display_name,
  norm(g.name)    as normalized,
  'global'::text  as source,
  null::uuid      as owner_id
from global_ingredients g
where g.visibility = 'public' or g.visibility is null
union all
select
  u.id::bigint       as row_id,
  u.name::text       as display_name,
  norm(u.name::text) as normalized,
  'personal'::text   as source,
  u.user_id          as owner_id
from user_ingredients u;

-- Speed up lookups on normalized text
create index if not exists ix_ing_search_normalized
  on ingredient_search_entries (normalized);

-- RPC for client use
create or replace function search_ingredients(q text, uid uuid, lim int default 20)
returns table (row_id bigint, label text, source text)
security definer
set search_path = public
language sql
as $$
  with qn as (select norm(q) as n)
  select s.row_id, s.display_name as label, s.source
  from ingredient_search_entries s, qn
  where
    (s.source = 'global'   and s.normalized like '%' || qn.n || '%')
    or
    (s.source = 'personal' and s.owner_id = uid and s.normalized like '%' || qn.n || '%')
  group by s.row_id, s.display_name, s.source
  order by (s.source = 'global') desc, s.display_name asc
  limit lim;
$$;
