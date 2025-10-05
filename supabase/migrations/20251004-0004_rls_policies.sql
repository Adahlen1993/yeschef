-- Enable RLS
alter table global_ingredients enable row level security;
alter table user_ingredients   enable row level security;

-- Global read-only to clients
drop policy if exists global_read_all on global_ingredients;
create policy global_read_all
  on global_ingredients
  for select
  using (true);

-- Personal: owner-only
drop policy if exists user_ing_select_own on user_ingredients;
create policy user_ing_select_own
  on user_ingredients
  for select using (auth.uid() = user_id);

drop policy if exists user_ing_insert_own on user_ingredients;
create policy user_ing_insert_own
  on user_ingredients
  for insert with check (auth.uid() = user_id);

drop policy if exists user_ing_update_own on user_ingredients;
create policy user_ing_update_own
  on user_ingredients
  for update using (auth.uid() = user_id);

drop policy if exists user_ing_delete_own on user_ingredients;
create policy user_ing_delete_own
  on user_ingredients
  for delete using (auth.uid() = user_id);
