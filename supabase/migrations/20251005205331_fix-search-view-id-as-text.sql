-- Cleanup the previous versions if they exist
drop function if exists search_ingredients(text, uuid, int);
drop view if exists ingredient_search_entries;

-- Normalizer (safe to re-create)
create or replace function norm(txt text) returns text
language sql immutable as $$
  select lower(trim(txt))
$$;

-- Unified search with TEXT id (works whether ids are bigint or uuid)
create or replace view ingredient_search_entries as
select
  g.id::text     as row_key,        -- <-- TEXT now
  g.name         as display_name,
  norm(g.name)   as normalized,
  'global'::text as source,
  null::uuid     as owner_id
from global_ingredients g
where g.visibility = 'public' or g.visibility is null
union all
select
  u.id::text       as row_key,      -- <-- TEXT now (uuid or bigint OK)
  u.name::text     as display_name,
  norm(u.name::text) as normalized,
  'personal'::text as source,
  u.user_id        as owner_id
from user_ingredients u;

-- Helpful index on normalized term
create index if not exists ix_ing_search_normalized
  on ingredient_search_entries (normalized);

-- RPC now returns TEXT row_key instead of BIGINT
create or replace function search_ingredients(q text, uid uuid, lim int default 20)
returns table (row_key text, label text, source text)
security definer
set search_path = public
language sql
as $$
  with qn as (select norm(q) as n)
  select s.row_key, s.display_name as label, s.source
  from ingredient_search_entries s, qn
  where
    (s.source = 'global'   and s.normalized like '%' || qn.n || '%')
    or
    (s.source = 'personal' and s.owner_id = uid and s.normalized like '%' || qn.n || '%')
  group by s.row_key, s.display_name, s.source
  order by (s.source = 'global') desc, s.display_name asc
  limit lim;
$$;
