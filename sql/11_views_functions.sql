-- Unified search view for canonical names + aliases (uses immutable public.norm)
create or replace view public.ingredient_search_entries as
select
  i.id as ingredient_id,
  i.name as display_name,
  public.norm(i.name) as normalized,
  'canonical'::text as source
from public.ingredients i
where i.visibility='public' or i.created_by = auth.uid()
union all
select
  a.ingredient_id,
  a.alias as display_name,
  public.norm(a.alias) as normalized,
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
         similarity(s.normalized, public.norm(q)) as similarity
  from public.ingredient_search_entries s
  where s.normalized % public.norm(q)
  order by similarity desc
  limit lim;
$$;
