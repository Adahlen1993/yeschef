-- Ensure extension exists
create extension if not exists unaccent;

-- Immutable wrapper around unaccent() so we can use it in indexes
create or replace function public.immutable_unaccent(text)
returns text
language sql
immutable
parallel safe
as $$
  select unaccent('public.unaccent', $1)
$$;

-- One-shot normalizer we can reuse everywhere (lower + unaccent)
create or replace function public.norm(text)
returns text
language sql
immutable
parallel safe
as $$
  select lower(public.immutable_unaccent($1))
$$;
