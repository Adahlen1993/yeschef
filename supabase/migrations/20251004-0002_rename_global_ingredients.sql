-- Rename the table you had already
alter table if exists ingredients rename to global_ingredients;

-- Case-insensitive unique name in global list (keeps TEXT, uses index)
create unique index if not exists global_ingredients_name_unique_idx
  on global_ingredients (lower(name));
