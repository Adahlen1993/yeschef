-- Personal ingredients
create table if not exists user_ingredients (
  id           bigint generated always as identity primary key,
  user_id      uuid   not null references auth.users(id) on delete cascade,
  name         citext not null,
  default_unit text,
  created_at   timestamptz default now(),
  constraint user_ingredients_unique_per_user unique (user_id, name)
);

-- Suggestions (for admin promotion signals)
create table if not exists ingredient_suggestions (
  name       citext not null,
  user_id    uuid   not null references auth.users(id) on delete cascade,
  created_at timestamptz default now(),
  constraint ingredient_suggestions_pk primary key (user_id, name)
);

create or replace view ingredient_suggestion_counts as
select lower(name) as normalized_name, count(*)::int as suggest_count
from ingredient_suggestions
group by lower(name)
order by suggest_count desc;
