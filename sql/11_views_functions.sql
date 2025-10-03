-- Unified search view for canonical names + aliases
create or replace view public.ingredient_search_entries as
select
  i.id as ingredient_id,
  i.name as display_name,
  i.normalized_name as normalized,
  'canonical'::text as source
from public.ingredients i
where i.visibility='public' or i.created_by = auth.uid()
union all
select
  a.ingredient_id,
  a.alias as display_name,
  a.normalized_alias as normalized,
  'alias'::text as source
from public.ingredient_aliases a
join public.ingredients i on i.id = a.ingredient_id
where i.visibility='public' or i.created_by = auth.uid();

-- RPC: fuzzy ingredient search (for typeahead)
create or replace function public.ingredient_search(q text, lim int default 10)
returns table (
  ingredient_id uuid,
  display_name text,
  source text,
  similarity double precision
)
language sql stable
as $$
  select s.ingredient_id, s.display_name, s.source,
         similarity(s.normalized, lower(unaccent(q))) as similarity
  from public.ingredient_search_entries s
  where s.normalized % lower(unaccent(q))
  order by similarity desc
  limit lim;
$$;

-- Helpful indexes
do $$
begin
  if not exists (select 1 from pg_indexes where schemaname='public' and indexname='pantry_items_user_updated_idx') then
    create index pantry_items_user_updated_idx on public.pantry_items (user_id, updated_at desc);
  end if;
end $$;
