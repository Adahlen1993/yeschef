-- Recipes (canonical or user)
create table if not exists public.recipes (
  id uuid primary key default gen_random_uuid(),
  author_user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  description text,
  time_minutes int,
  servings_default int default 2,
  cuisine text,
  visibility text not null default 'private' check (visibility in ('public','private')),
  is_canonical boolean default false,
  likes_count int default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.recipes enable row level security;

do $$
begin
  if exists (select 1 from pg_policies where schemaname='public' and tablename='recipes' and policyname='recipes_select_public_or_own') then
    drop policy "recipes_select_public_or_own" on public.recipes;
  end if;
  if exists (select 1 from pg_policies where schemaname='public' and tablename='recipes' and policyname='recipes_write_own') then
    drop policy "recipes_write_own" on public.recipes;
  end if;
end $$;

create policy "recipes_select_public_or_own" on public.recipes
for select using (visibility='public' or author_user_id = auth.uid());

create policy "recipes_write_own" on public.recipes
for all using (author_user_id = auth.uid()) with check (author_user_id = auth.uid());

drop trigger if exists trg_recipes_touch on public.recipes;
create trigger trg_recipes_touch before update on public.recipes
for each row execute procedure public.touch_updated_at();

-- Ingredients in a recipe
create table if not exists public.recipe_ingredients (
  recipe_id uuid not null references public.recipes(id) on delete cascade,
  ingredient_id uuid not null references public.ingredients(id) on delete restrict,
  quantity numeric,
  unit text references public.units(code),
  optional boolean default false,
  note text,
  primary key (recipe_id, ingredient_id)
);

-- Steps (ordered)
create table if not exists public.recipe_steps (
  id uuid primary key default gen_random_uuid(),
  recipe_id uuid not null references public.recipes(id) on delete cascade,
  step_number int not null,
  instruction text not null,
  media_url text,
  timer_seconds int
);
create index if not exists recipe_steps_order_idx on public.recipe_steps (recipe_id, step_number);

-- Tags & join
create table if not exists public.tags (
  id uuid primary key default gen_random_uuid(),
  name text not null unique
);
create table if not exists public.recipe_tags (
  recipe_id uuid not null references public.recipes(id) on delete cascade,
  tag_id uuid not null references public.tags(id) on delete cascade,
  primary key (recipe_id, tag_id)
);

-- Images
create table if not exists public.recipe_images (
  id uuid primary key default gen_random_uuid(),
  recipe_id uuid not null references public.recipes(id) on delete cascade,
  url text not null,
  sort_order int default 0
);

-- Favorites & Saves
create table if not exists public.recipe_favorites (
  user_id uuid not null references public.profiles(id) on delete cascade,
  recipe_id uuid not null references public.recipes(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, recipe_id)
);
alter table public.recipe_favorites enable row level security;
do $$
begin
  if exists (select 1 from pg_policies where schemaname='public' and tablename='recipe_favorites' and policyname='recipe_favorites_rw_own') then
    drop policy "recipe_favorites_rw_own" on public.recipe_favorites;
  end if;
end $$;
create policy "recipe_favorites_rw_own" on public.recipe_favorites
for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create table if not exists public.recipe_saves (
  user_id uuid not null references public.profiles(id) on delete cascade,
  recipe_id uuid not null references public.recipes(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, recipe_id)
);
alter table public.recipe_saves enable row level security;
do $$
begin
  if exists (select 1 from pg_policies where schemaname='public' and tablename='recipe_saves' and policyname='recipe_saves_rw_own') then
    drop policy "recipe_saves_rw_own" on public.recipe_saves;
  end if;
end $$;
create policy "recipe_saves_rw_own" on public.recipe_saves
for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Track clones (user copies a recipe)
create table if not exists public.recipe_copies (
  id uuid primary key default gen_random_uuid(),
  src_recipe_id uuid not null references public.recipes(id) on delete cascade,
  new_recipe_id uuid not null references public.recipes(id) on delete cascade,
  copied_by uuid not null references public.profiles(id) on delete cascade,
  copied_at timestamptz not null default now()
);
